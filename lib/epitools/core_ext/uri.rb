require 'uri'

module URI

  #
  # Return a Hash of the variables in the query string
  #
  def params
    (@query ? @query.to_params : {})
  end

  #
  # Mutate the query
  # NB: This is super slow. To make it faster, store params directly in a locally cached dict, and only call `to_query` when query is accesed, or to_s/inspect are called
  #
  def params=(key, value)
    current      = params
    current[key] = value
    self.query   = current.to_query
  end

  def query
    params.to_query
  end

  #
  # URIs are strings, dammit!
  #
  def to_str
    to_s
  end

  #
  # Default user agent for the 'get' method
  #
  # USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:61.0) Gecko/20100101 Firefox/61.0"

  #
  # Get this URI using Net::HTTP
  #
  def get(headers={}, redirect_limit=10)
    raise "Sorry, URI can't get from #{scheme.inspect} URIs yet" unless scheme =~ /^https?$/
    raise 'Too many HTTP redirections' if redirect_limit == 0

    # headers['User-Agent'] ||= USER_AGENT

    # response = Net::HTTP.start(host, port) do |http|
    #   # the_path = path.empty? ? "/" : path
    #   req = Net::HTTP::Get.new(self, headers)
    #   http.request(req)
    # end

    response = Net::HTTP.get_response(self)

    case response
    when Net::HTTPSuccess
      response
    when Net::HTTPRedirection
      # puts "redirect: #{response['location']}"
      URI(response['location']).get(headers, redirect_limit-1)
    else
      response.error!
    end
  end

end

#
# Stupid workaround for URI blowing up when it receives a [ or ] character
#
module Better_URI_RFC3986_Parser # ::RFC3986_relative_ref
  ESCAPE_ME_PLZ = "[]{}!"

  def split(uri)
    subsitutions = ESCAPE_ME_PLZ.chars.map { |c| [c, CGI.escape(c)] }
    subsitutions << [" ", "%20"]

    subsitutions.each do |find, replace|
      uri = uri.gsub(find, replace)
    end

    super(uri)
  end

end

URI::RFC3986_Parser.prepend(Better_URI_RFC3986_Parser)

