#
# A Regex-queryable Hash.
#
# Usage:
#
#     greeting = Rash.new( /^Mr./ => "Hello sir!", /^Mrs./ => "Evening, madame." )
#     greeting["Mr. Steve Austin"] #=> "Hello sir!"
#     greeting["Mrs. Steve Austin"] #=> "Evening, madame."
#
class Rash
  
  attr_accessor :optimize_every
  
  def initialize(initial={})
    @hash           = {}
    @regexes        = []
    @regex_counts   = Hash.new(0)
    @optimize_every = 500
    @lookups        = 0
    
    update(initial)
  end

  def []=(key, value)
    if key.is_a? Regexp
      #key = normalize_regex(key)  # this used to just do: /#{regexp}/
      @regexes << key
    end
    @hash[key] = value
  end
  
  def search_regexes(string)
    @regexes.select { |r| string =~ r }.map { |r| @regex_counts[regex] += 1; @hash[r] } 
  end
  
  def search_strings(regex)
    keys.select { |key| key =~ regex if key.is_a? String }.map{ |key| @hash[key] }    
  end
  
  def [](key)
    return @hash[key] if @hash.include? key

    case key
      
      when String
        optimize_if_necessary!
        
        regexes = @regexes.select { |r| r =~ key }
        
        if regexes.any?
          return regexes.map do |regex|
            @regex_counts[regex] += 1 
            @hash[regex]  
          end
        end
        
      when Regexp
        
        matches = search_strings(key)
        
        if matches.any?
          return matches
        end
      
    else
      return @hash[key]
    end

    nil
  end
  
  def update(other)
    for key, value in other
      self[key] = value
    end
    self
  end
  
  def method_missing(*args, &block)
    @hash.send(*args, &block)
  end

private

  def optimize_if_necessary!
    if (@lookups += 1) >= @optimize_every    
      @regexes = @regex_counts.sort_by { |regex,count| -count }.map { |regex,count| regex }
      @lookups = 0
    end
  end

end

