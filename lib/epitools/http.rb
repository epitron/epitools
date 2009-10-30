require 'net/http'
require 'uri'

# TODO: what?? this needs to be a class.

class PartialPage < Exception
    attr_accessor :data
end

def read_data_from_response(response, amount)
  
  amount_read = 0
  chunks = []
  
  begin
      
      response.read_body do |chunk|   # read body now
        
        amount_read += chunk.length
        
        if amount_read > amount
          amount_of_overflow = amount_read - amount
          chunk = chunk[0...-amount_of_overflow]
        end
        
        chunks << chunk
  
        if amount_read >= amount
            raise PartialPage.new chunks.join('')
        end
        
      end
  end
  
end



def http_get_streaming(url = URI.parse("http://epi.is-a-geek.net/files/Mr.%20Show%20-%20Civil%20War%20Re-enactment.avi"))

  #headers = {'User-Agent' => "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1"}
  headers = nil
  
  Net::HTTP.start(url.host, url.port) do |http|
      # using block
      response = http.request_get(url.path, headers) {|response|
        puts "Response: #{response.inspect}"
        puts "to hash: #{response.to_hash.inspect}"
  
        begin
          read_data_from_response(response, 500)
        rescue PartialPage => p
          puts "GOT THE PARTIAL PAGE!"
          data = p.data
        end
      
        puts
        puts "===========first 500 bytes================="
        puts data
      }    
  end

end


# TODO: Remove RIO dependancy.

def http_get_cached(url)
  require 'digest/md5'
  require 'rio'
  
	tempdir = ENV['TEMP']
	cachefile = rio(tempdir, "cached_url_#{Digest::SHA1.hexdigest(url)}")
	
	if cachefile.exist?
		data = rio(cachefile).read
	else
		data = rio(url).read
		rio(cachefile).binmode < data
	end
	
	data
end

