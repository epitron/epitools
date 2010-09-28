require 'mechanize'
require 'socksify'
require 'uri'
require 'fileutils'

require 'progress_patch'
require 'db'
require 'cachedb'

Time.zone = "UTC"

$VERBOSE = nil

class DateTime
  def to_i
    to_f.to_i
  end
end

class String

  #
  # Remove redundant whitespace
  #
  def tighten
    gsub(/[\t ]+/,' ').strip
  end

  #
  # Remove redundant whitespace and newlines 
  #
  def dewhitespace
    gsub(/\s+/,' ').strip
  end

  #
  # Is this Unicodey?
  #
  def unicode?
    unpack("U*").any? { |x| x > 127 }
  rescue ArgumentError
    false
  end

  #
  # Replace all the "bad" unicode chars
  #
  def fix_unicode
    begin
      newstring = unpack("U*").map do |c|
        case c
          when 160 then 32
          when 173 then ?-
          else c
        end
      end
    rescue ArgumentError
      newstring = unpack("C*").map{|c| c > 127 ? ?* : c }
    end

    newstring.pack("U*")
  end

  def to_timestamp(fmt)
    DateTime.strptime(self, fmt).to_i #+ Time.zone.utc_offset
  end

end

class BrowserOptions < OpenStruct
  
  def initialize(opts)
    
  end
  
end

class Browser

  attr_accessor :agent, :cache, :use_cache, :delay, :delay_jitter

  def initialize(options={})
    @last_get     = Time.zone.at(0)
    @delay        = options[:delay]         || 1
    @delay_jitter = options[:delay_jitter]  || 0.2
    @use_cache    = options[:cache]         || true
    @use_logs     = options[:logs]          || false
    @cookie_file  = options[:cookiefile]    || "cookies.txt"

    if options[:proxy]
      host, port = options[:proxy].split(':')
      TCPSocket::socks_server = host
      TCPSocket::socks_port   = port.to_i
    end

    init_agent!
    init_cache!
  end


  def init_agent!
    @agent = Mechanize.new do |a|
      # ["Mechanize", "Mac Mozilla", "Linux Mozilla", "Windows IE 6", "iPhone", "Linux Konqueror", "Windows IE 7", "Mac FireFox", "Mac Safari", "Windows Mozilla"]
      a.max_history = 10 
      a.user_agent_alias = "Windows IE 7"
      a.log = Logger.new "mechanize.log" if @use_logs
    end

    load_cookies!
  end


  def delay(override_delay=nil, override_jitter=nil)
    elapsed   = Time.zone.now - @last_get
    jitter    = rand * (override_jitter || @delay_jitter)
    amount    = ( (override_delay || @delay) + jitter ) - elapsed

    if amount > 0
      puts "  |_ sleeping for %0.3f seconds..." % amount
      sleep amount
    end
  end


  def init_cache!
    require 'sqlite3'
    @cache = CacheDB.new(agent) if @use_cache
  end


  def relative?(url)
    not url =~ %r{^https?://}
  end


  def cache_put(page, url)
    if page.is_a? Mechanize::Page and page.content_type =~ %r{^text/}
      puts "  |_ writing to cache"
      cache.put(page, url, :overwrite=>true)
    end
  end

  def get(url, options={})

    if relative?(url)
      url = URI.join("http://messageboard.yuku.com/", url).to_s
    end

    # Determine the cache setting
    options[:use_cache] ||= @use_cache
    
    if options[:use_cache] == false
      options[:read_cache]  = false
      options[:write_cache] = false
    end
    
    options[:read_cache]  = true   if options[:read_cache].nil?
    options[:write_cache] = true   if options[:write_cache].nil? 

    read_cache  = options[:read_cache] && cache.include?(url) 
    write_cache = options[:write_cache]

    puts
    puts "[ #{url.inspect} (read_cache=#{options[:read_cache]}, write_cache=#{options[:write_cache]}) ]"
    
    delay unless read_cache

    begin
      
      if read_cache
        page = cache.get(url)
        if page.nil?
          puts "  |_ CACHE FAIL! Re-getting page."
          page = get(url, false)
        end
        puts "  |_ cached (#{page.content_type})"
      else
        if url["yuku.com"]
          page = login_get url
        else
          page = agent.get url
        end
        @last_get = Time.zone.now
      end

      cache_put(page, url) if write_cache and not read_cache

      puts

    rescue Net::HTTPBadResponse, Errno::ECONNRESET, SocketError, Timeout::Error, SOCKSError => e
      puts "  |_ ERROR: #{e.inspect} -- retrying"
      delay(5)
      retry
      
    rescue Mechanize::ResponseCodeError => e
      raise e unless url["yuku.com"]
      
      case e.response_code
        when "401" #=> Net::HTTPUnauthorized
          p e
          login!
          page = get(url)
          puts
        when "404"
          p e
          raise e
        when "503"
          puts "  |_ ERROR: #{e.inspect} -- retrying"
          delay(5)
          retry
      else
        raise e
      end
      
    end

    page
  end


  def logged_in?(page)
    not page.uri.path == "/login/loginnow/Login-to-Yuku.html"
  end


  def login!
    puts "* Logging in..."
    page = agent.get('http://messageboard.yuku.com/login/loginnow/Login-to-Yuku.html', false)

    return true if logged_in?(page)

    form = page.forms.last #find{|f| f.action["/login/view"] }

    raise "No form?!" unless form

    form.login = LOGIN
    form.password = PASSWORD

    nextpage = form.submit

    if logged_in?(nextpage)
      save_cookies!
    else
      raise "Error logging in."
    end
  end

  ######################################################################
  ## Scrape content
  ######################################################################

  def forums(get_opts={}, &block)
    return Enumerable::Enumerator.new(self, :forums, get_opts) unless block_given?
    #ems = page.search("dir-10 .evencol a , .even .evencol a")
    #ems.map { |em| [em[:title], em[:href]] }

    page = get("http://messageboard.yuku.com/", get_opts)
    forums = page.search(".boxbody table tbody tr")

    forums.each do |forum|
      link = forum.at(".forumtitle h3 a")
      next if link[:title] == "Chat"

      url = link[:href]
      name = link[:title]
      if url =~ %r{/forums/(\d+)}
        record_id = $1.to_i
      else
        raise "Couldn't get forum id: #{url}"
      end

      description = forum.at(".forumtitle h4.description").text

      last_post_string = forum.at(".latest .date").text.dewhitespace
      last_post = last_post_string.to_timestamp("%m/%d/%y %l:%M %p")
      result = {
        :id => record_id,
        :name => link[:title],
        :url => link[:href],
        :last_post => last_post,
        :description => description,
        :posts => (node = forum.at("td.posts") and node.text.dewhitespace.to_i),
        :topics => (node = forum.at("td.topics") and node.text.dewhitespace.to_i),
        :kudos => (node = forum.at("td.kudos") and node.text.dewhitespace.to_i),
      }

      yield result
    end

  end

  def last_page_url(page)
    if pagerlist = page.at(".pager-holder .pager-list")
      pages = pagerlist.search(".number a")
      pages.last["href"]
    end
  end

  def topics(url="/forums/79", forum=nil, get_opts={}, &block)
    return Enumerable::Enumerator.new(self, :topics, url, forum, get_opts) unless block_given?

    next_page = url

    while next_page
      page = get(next_page, get_opts)

      next_page = (node = page.at(".pager-holder .pager-list div[@class='next active'] a") and node[:href])
      #p [:last_page, last_page = last_page_url(page)]

      topics = page.search(".forum-box .boxbody table tbody tr")

      topics.each do |t|
        classes = t[:class].split

        next if classes.include? "row-moved"  # topic has been moved.

        a = t.at("td.topic-titles a")

        url = a[:href]
        if url =~ %r{/topic/(\d+)}
          record_id = $1.to_i
        else
          raise "Can't find topic id: #{url}"
        end

        # fixme?
        last_post_string = t.at("td.latest p.date").text.dewhitespace
        last_post = last_post_string.to_timestamp("%m/%d/%y %l:%M %p")

        result = {
          :id     => record_id,
          :sticky => classes.include?("row-sticky"),
          :hot    => classes.include?("row-hot"),
          :closed => classes.include?("row-closed"),
          :url    => url,
          :title  => a.text.fix_unicode.strip,
          :views  => t.at(".views").text.to_i,
          :kudos  => t.at(".kudos").text.to_i,
          :replies => t.at(".replies").text.to_i,
          :last_post => last_post,
        }

        yield result
      end

      Latest.set_forum_url(forum, next_page) if forum
      #topics(next_page, forum, &block)
    end

  end

  def parse_posts(page)
    #return Enumerator::Enumerable.new(self, :parse_posts) unless block_given?
    results = []

    posts = page.search(".boxbody > table > tbody.thread-post")

    posts.each do |post|

      #= <a href="http://seediver.u.yuku.com" title="seediver's Profile">seediver</a>
      poster_link = post.at("td.poster-name span.user-name a")

      avatar = nil
      if node = post.at(".poster-detail .avatar-block p.user-avatar a img")
        unless node[:src] =~ /missinng_avatar/
          avatar = node[:src]
        end
      end

      custom_title = (node = post.at(".poster-detail .avatar-block p.custom_title") and node.text)
      if custom_title
        custom_title = nil if custom_title.strip.empty?
      end

      user_info = {
        :url => poster_link[:href],
        :avatar => avatar,
        :title => custom_title ? custom_title.strip : "Standard",
        :signature => (node = post.at(".signature .scrolling") and node.children.to_s.tighten),
      }

      last_edited = nil
      if node = post.at(".edit-info")
        if node.text =~ %r{(\d\d/\d\d/\d\d \d{1,2}:\d\d \w\w)}
          last_edited = $1.to_timestamp("%m/%d/%y %l:%M %p")
        end
      end

      timestring = (node = post.at(".poster-detail .avatar-block p.post-date") and node.text.dewhitespace)
      timestamp = timestring.to_timestamp("(%m/%d/%y %l:%M %p)")

      if node = post.at("td.post-number")
        case node.text.strip
          when /^#(\d+)$/
            post_number = $1.to_i
          when /Lead/
            post_number = 0
        else
          p node.text
          raise "Couldn't find post number!"
        end
      end

      subject = (node = post.at("td.post-subject .post-title") and node.text.tighten)

      ## Fix for <script>googleFillThing</script> problem, seen here:
      body_divs = post.search(".post-body .scrolling div")
      body_divs.shift if body_divs.size > 1
      body = body_divs.children.to_s.tighten.gsub("\n", "")

      result = {
        #:id => record_id,
        :username => poster_link.text.strip,
        :user_info => user_info,
        :post_number => post_number,
        :timestamp => timestamp,
        :timestring => timestring,
        :post_body => body.fix_unicode,
        :poll_body => (node = post.at(".post-content .poll-body") and node.children.to_s.tighten),
        :last_edited => last_edited,
        :post_subject => subject.fix_unicode,
      }

      results << result
    end

    results

  end

  def posts(url="/topic/7247", get_opts={}, &block)
    return Enumerable::Enumerator.new(self, :posts, url, get_opts) unless block_given?

    page      = get(url, get_opts)
    next_page = (node = page.at(".pager-holder .pager-list div[@class='next active'] a") and node[:href])

    parse_posts(page).each {|post| yield post}

    posts(next_page, get_opts, &block) if next_page
  end

  def parse_ka_profile(pwage)
    raise "Bad profile!"
  end

  def parse_profile(page)

    result = {}

    infos = page.search(".userinfo-holder ul.userinfo li").map{|e| e.text.split(/:\s+/, 2)}

    for key, value in infos
      next unless value
      #p [key, value]

      value.strip!

      case key
        when "Name"
          result[:real_name] = value
        when "Gender"
          result[:gender] = value
        when "Age"
          result[:age] = value
        when "Location", "Lives In"
          result[:location] = value

      else
        #p [:UNKNOWN_INFO, key, value]
        p [:unknown, key]
      end

    end

    page.search(".column_b .box").each do |box|
      heading = box.at(".boxheading").text.tighten
      body = box.at(".boxbody").text.tighten
      #p [heading]

      case heading
        when "My Bio"
          result[:bio] = body
        when "My Occupation"
          result[:occupation] = body
        when "My Hobbies"
          result[:interests] = body
      else
        p [:unknown, heading]
        #p [:UNKNOWN_BOX, heading, body]
      end
    end

    stats = page.at("table.userstats")

    last_post = ( node = stats.at("td.last-post") and node.text.dewhitespace.to_timestamp("%m/%d/%y %H:%M:%S") )
    last_seen = ( node = stats.at("td.last-seen") and node.text.dewhitespace.to_timestamp("%m/%d/%y %H:%M:%S") )
    joined    = ( node = stats.at("td.joined") and node.text.to_timestamp("%m/%d/%y") )

    if page.title =~ /^(.+) Profile Yuku$/
      username = $1
    else
      raise "Cannot parse username."
    end

    avatar = nil
    if node = page.at("a.avatar img")
      unless node[:src] =~ /missinng_avatar/
        avatar = node[:src].strip
      end
    end

    result
  end
  
  def user_profile(url="http://ransom.u.yuku.com/")

    page = get url

    if page.at("#ka-page")
      parse_ka_profile(page)
    else
      parse_profile(page)
    end
  end

  #
  # Admin style
  #
  def user_pages_private(url=nil, get_opts={}, &block)
    return Enumerable::Enumerator.new(self, :user_pages_private, url, get_opts) unless block_given?

    url = "/members/all/type/basic/status_2/all/orderby/joined/order/asc" if url.nil?

    page = get(url, get_opts)

    next_page = (node = page.at(".mgr-boxbody .mgr-pager .mgr-next a") and node[:href])

    page.search("table#filtered-data tr").each do |row|

      next if row.at("th")

      if a = row.at("td.user-name a")
        username = a.text.tighten.gsub(/\(d\)$/, '')
        url = a["href"]
        uid = ( url =~ %r{/members/management/id/(\d+)} and $1.to_i )
      else
        raise "Error: couldn't parse #{row.to_s}"
      end

      joined = ( str = row.at("td.join-date").text and str.to_timestamp("%m/%d/%y") )
      last_seen = ( str = row.at("td.last-seen").text and str.dewhitespace.to_timestamp("%m/%d/%y") )
      status = ( node = row.at("td.status div") and node.text.tighten )
      kudos = ( node = row.at("td.kudos-count") and node.text.to_i )
      posts = ( node = row.at("td.post-count") and node.text.to_i )

      result = {
        :username => username,
        #:url => url,
        :uid => uid,
        :status => status,
        :joined => joined,
        :kudos  => kudos,
        :posts  => posts,
        :last_seen => last_seen,
      }

      yield result

    end

    user_pages_private(next_page, get_opts, &block) if next_page
  end


  #
  # Admin style
  #
  def user_info_private(url="/members/management/id/801734")

    result = {}

    page = get url

    if a = page.at(".mgr-member-detail .mgr-boxheading h2 a")
      result[:username] = a.text.tighten
      result[:url] = a["href"]
    end

    result[:avatar] = ( img = page.at(".mgr-member-detail .avatar a img") and img["src"] )

    infos = page.search(".mgr-member-detail ul.local-stats li").map{|e| e.text.split(/:\s+/, 2)}

    result
  end

  def profile_url(uid)
    result = user_info_private("/members/management/id/#{uid}")
    result[:url]
  end


  ######################################################################

  def broadcast(recipients=[], subject="Test", body="Test message!")
    page = get("http://messageboard.yuku.com/messages/sendmessage")
    form = page.forms.find { |f| f.action["sendmessage"] }
    for recipient in recipients
      private_message(form, recipient, subject, body)
    end
  end

  def private_message(form, recipient, subject="Test", body="Test message!")
    # params: ["receiver", "cc", "bcc", "subject", "tags", "message", "selected_name"]
    # CODES!<br><br><span style="font-weight: bold;">bold</span><br><br><span style="font-style: italic;">italic...</span><br><br><span style="text-decoration: underline;">Underline</span><br><br><div style="text-align: center;">CENTER!<br></div>
    form.receiver       = recipient
    form.selected_name  = "6494530"
    form.subject        = subject
    form.message        = body

    nextpage = form.submit

    if nextpage.body =~ /Your message has been successfully sent/
      puts "* SENT: #{recipient}"
    else
      puts "******* ERROR: couldn't send to #{recipient} *********"
    end    
  end

private

  def load_cookies!
    agent.cookie_jar.load COOKIE_FILE if File.exists? COOKIE_FILE
  end

  def save_cookies!
    agent.cookie_jar.save_as COOKIE_FILE
  end

end


$s = Scraper.new
