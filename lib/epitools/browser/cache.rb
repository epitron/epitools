require 'mechanize'
require 'sqlite3'

#
# Emit a quick debug message (only if $DEBUG is true)
#
def dmsg(msg)
  
  if $DEBUG
    case msg
      when String
        puts msg
      else
        puts msg.inspect
    end
  end
  
end

class Browser
  
  #
  # An SQLite3-backed browser cache (with gzip compressed pages)
  #
  class Cache
  
    include Enumerable
  
    attr_reader :db, :agent
  
    def initialize(agent, filename="browsercache.db")
      @agent    = agent
      @filename = filename
  
      @db = SQLite3::Database.new(filename)
      @db.busy_timeout(50)
  
      create_tables
    end
  
    def inspect
      "#<Browser::Cache filename=#{@filename.inspect}, count=#{count}, size=#{File.size @filename} bytes>"
    end
  
    def count
      db.execute("SELECT COUNT(1) FROM cache").first.first.to_i
    end
    
    alias_method :size, :count
  
    def valid_page?(page)
      [:body, :content_type, :uri].all?{|m| page.respond_to? m }
    end
       
    
    def put(page, original_url=nil, options={})
      dmsg [:put, original_url]
  
      raise "Invalid page" unless valid_page?(page) 
  
      url = page.uri.to_s
  
      dmsg [:page_uri, url]
      dmsg [:original_url, url]
  
      if url != original_url
        # redirect original_url to url
        expire(original_url) if options[:overwrite]
        db.execute(
          "INSERT INTO cache VALUES ( ?, ?, ?, ? )",
          original_url,
          page.content_type,
          nil,
          url
        )
      end
  
      #compressed_body = page.body
      compressed_body = Zlib::Deflate.deflate(page.body)

      expire(url) if options[:overwrite]
      db.execute(
        "INSERT INTO cache VALUES ( ?, ?, ?, ? )",
        url,
        page.content_type,
        SQLite3::Blob.new( compressed_body  ),
        nil
      )
  
      true
      
    rescue SQLite3::SQLException => e
      p [:exception, e]
      false
    end
  
    def row_to_page(row)
      url, content_type, compressed_body, redirect = row
  
      if redirect
        get(redirect)
      else
        #body = compressed_body
        body = Zlib::Inflate.inflate(compressed_body)
  
        if content_type =~ /^(text\/html)|(application\/xhtml\+xml)/i
          Mechanize::Page.new(
            #initialize(uri=nil, response=nil, body=nil, code=nil, mech=nil)
            URI.parse(url),
            {'content-type'=>content_type},
            body,
            nil,
            agent
          )
        else
          Mechanize::File.new(
            #initialize(uri=nil, response=nil, body=nil, code=nil
            URI.parse(url),
            {'content-type'=>content_type},
            body,
            nil
          )
        end
            
      end
    end
  
    def pages_via_sql(*args, &block)
      dmsg [:pages_via_sql, args]
      if block_given?
        db.execute(*args) do |row|
          yield row_to_page(row)
        end
      else
        db.execute(*args).map{|row| row_to_page(row) }
      end
    end
  
    def grep(pattern, &block)
      pages_via_sql("SELECT * FROM cache WHERE url like '%#{pattern}%'", &block)
    end
  
    def get(url)
      pages = pages_via_sql("SELECT * FROM cache WHERE url = ?", url.to_s)
      
      if pages.any?
        pages.first
      else
        nil
      end
    end
  
    def includes?(url)
      db.execute("SELECT url FROM cache WHERE url = ?", url.to_s).any?
    end
  
    alias_method :include?, :includes?
  
    def urls(pattern=nil)
      if pattern
        rows = db.execute("SELECT url FROM cache WHERE url LIKE '%#{pattern}%'")
      else
        rows = db.execute('SELECT url FROM cache')
      end
      rows.map{|row| row.first}
    end
  
    def clear(pattern=nil)
      if pattern
        db.execute("DELETE FROM cache WHERE url LIKE '%#{pattern}%'")
      else
        db.execute("DELETE FROM cache") 
      end
    end
  
    def each(&block)
      pages_via_sql("SELECT * FROM cache", &block)
    end
  
    def each_url
      db.execute("SELECT url FROM cache") do |row|
        yield row.first
      end
    end
  
    def expire(url)
      db.execute("DELETE FROM cache WHERE url = ?", url)
    end
  
    def recreate_tables
      drop_tables rescue nil
      create_tables
    end
  
    def delete!
      File.unlink @filename  
    end
  
  private
  
    def list_tables
      db.execute("SELECT name FROM SQLITE_MASTER WHERE type='table'")
    end
  
    def create_tables
      db.execute("CREATE TABLE IF NOT EXISTS cache ( url varchar(2048), content_type varchar(255), body blob, redirect varchar(2048) )")
      db.execute("CREATE UNIQUE INDEX IF NOT EXISTS url_index ON cache ( url )")
    end
  
    def drop_tables
      db.execute("DROP TABLE cache")
    end
  
  end
  
end
