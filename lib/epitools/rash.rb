
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
      key = normalize_regex(key)
      @regexes << key
    end
    @hash[key] = value
  end
  
  def [](key)
    return @hash[key] if @hash.include? key

    if key.is_a? String
      optimize! if (@lookups += 1) >= @optimize_every
      
      if regex = @regexes.find { |r| r =~ key }
        @regex_counts[regex] += 1
        return @hash[regex]
      end
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

  def optimize!
    @regexes = @regex_counts.sort_by { |regex,count| -count }.map { |regex,count| regex }
    @lookups = 0
  end

  def normalize_regex(regex)
    /^#{regex}$/
  end
  
end



if $0 == __FILE__
  r = Rash.new(
    /hello/ => "hello",
    /world/ => "world!",
    "other" => "whee",
    true    => false,
    1       => "awesome"
    # /.+/ => "EVERYTHING"
  )
  
  p r
  p [ r["hello"], r["world"], r["other"], r[1], r[true] ]
  
end

