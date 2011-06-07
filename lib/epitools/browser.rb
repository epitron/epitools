require 'epitools'
require 'mechanize'
require 'epitools/browser/cache'
require 'epitools/browser/mechanize_progressbar'

# TODO: Make socksify optional (eg: if proxy is specified)
#require 'socksify'
class SOCKSError < Exception; end # :nodoc:

#
# Slightly more intelligent `Mechanize::File`s
#
class Mechanize::File
  def content_type
    response['content-type']
  end
end
  

#
# A mechanize class that emulates a web-browser, with cache and everything.
# Progress bars are enabled by default.
#
class Browser

  attr_accessor :agent, :cache, :use_cache, :delay, :delay_jitter

  #
  # Default options:
  #  :delay => 1,                      # Sleep 1 second between gets
  #  :delay_jitter => 0.2,             # Random deviation from delay
  #  :use_cache => true,               # Cache all gets
  #  :use_logs => false,               # Don't log the detailed transfer info
  #  :cookie_file => "cookies.txt"     # Save cookies to file
  #
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
    @cache = Cache.new(agent) if @use_cache
  end

  def load_cookies!
    if File.exists? @cookie_file
      agent.cookie_jar.load @cookie_file
      true
    else
      false
    end
  end
  
  def save_cookies!
    agent.cookie_jar.save_as @cookie_file
    true
  end
  
  def relative?(url)
    not url[ %r{^https?://} ]
  end
  
  def cacheable?(page)
    case page.content_type
    when %r{^(text|application)}
      true
    end
  end    
  
  def cache_put(page, url)
    if cache.valid_page?(page)
      if page.content_type =~ %r{(^text/|^application/javascript|javascript)}
        puts "  |_ writing to cache"
        cache.put(page, url, :overwrite=>true)
      end
    end
  end

  
  #
  # Retrieve an URL, and return a Mechanize::Page instance (which acts a 
  # bit like a Nokogiri::HTML::Document instance.)
  #
  # Options:
  #   :cached => true/false   | check cache before getting page
  #
  def get(url, options={})

    # TODO: Have a base-URL option
    
    #if relative?(url)
    #  url = URI.join("http://base-url/", url).to_s
    #end

    # Determine the cache setting
    use_cache = options[:cached].nil? ? @use_cache : options[:cached]

    cached_already = cache.include?(url)

    puts
    puts "[ GET #{url} (using cache: #{use_cache}) ]"
    
    delay unless cached_already

    begin
      
      if page = cache.get(url)
        puts "  |_ cached (#{page.content_type})"
      else
        page = agent.get(url)
        @last_get = Time.now
        cache_put(page, url)
      end

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

  
  #
  # Delegate certain methods to @agent
  #
  [:head, :post, :put, :submit].each do |meth|
    define_method meth do |*args|
      agent.send(meth, *args)
    end
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


