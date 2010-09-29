require 'mechanize'
require 'uri'
require 'fileutils'

require 'epitools/browser/mechanize_progressbar'

# TODO: Make socksify optional (eg: if proxy is specified)
#require 'socksify'

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
    DateTime.strptime(self, fmt).to_i
  end

end


# TODO: Put options here.
=begin
class BrowserOptions < OpenStruct

  DEFAULTS = {
    :delay => 1,
    :delay_jitter => 0.2,
    :use_cache => true,
    :use_logs => false,
    :cookie_file => "cookies.txt"
  }
  
  def initialize(extra_opts)
    
    @opts = DEFAULTS.dup
    
    for key, val in opts
      if key.in? DEFAULTS
        @opts[key] = val
      else
        raise "Unknown option: #{key}"
      end
    end
  end
  
end
=end

#
# A mechanize class that emulates a web-browser, with cache and everything.
# Progress bars are enabled by default.
#
class Browser

  attr_accessor :agent, :cache, :use_cache, :delay, :delay_jitter

  def initialize(options={})
    @last_get     = Time.at(0)
    @delay        = options[:delay]         || 1
    @delay_jitter = options[:delay_jitter]  || 0.2
    @use_cache    = options[:cache]         || true
    @use_logs     = options[:logs]          || false
    @cookie_file  = options[:cookiefile]    || "cookies.txt"
    
    # TODO: @progress, @user_agent, @logfile, @cache_file (default location: ~/.epitools?) 

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
    elapsed   = Time.now - @last_get
    jitter    = rand * (override_jitter || @delay_jitter)
    amount    = ( (override_delay || @delay) + jitter ) - elapsed

    if amount > 0
      puts "  |_ sleeping for %0.3f seconds..." % amount
      sleep amount
    end
  end


  def init_cache!
    # TODO: Rescue "couldn't load" exception and disable caching
    require 'epitools/browser/browser_cache'
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

    # TODO: Have a base-URL option
    
    #if relative?(url)
    #  url = URI.join("http://base-url/", url).to_s
    #end

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
        page = agent.get url
        @last_get = Time.now
      end

      cache_put(page, url) if write_cache and not read_cache

      puts

    rescue Net::HTTPBadResponse, Errno::ECONNRESET, SocketError, Timeout::Error, SOCKSError => e
      puts "  |_ ERROR: #{e.inspect} -- retrying"
      delay(5)
      retry
=begin      
    rescue Mechanize::ResponseCodeError => e
      
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
=end

    end

    page
  end

private

  def load_cookies!
    agent.cookie_jar.load @cookie_file if File.exists? @cookie_file
  end

  def save_cookies!
    agent.cookie_jar.save_as @cookie_file
  end

end

