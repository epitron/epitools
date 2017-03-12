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
    @ranges         = []
    @regex_counts   = Hash.new(0)
    @optimize_every = 500
    @lookups        = 0

    update(initial)
  end

  def update(other)
    for key, value in other
      self[key] = value
    end
    self
  end

  def []=(key, value)
    case key
    when Regexp
      #key = normalize_regex(key)  # this used to just do: /#{regexp}/
      @regexes << key
    when Range
      @ranges << key
    end
    @hash[key] = value
  end

  #
  # Return the first thing that matches the key.
  #
  def [](key)
    all(key).first
  end

  #
  # Return everything that matches the query.
  #
  def all(query)
    return to_enum(:all, query) unless block_given?

    if @hash.include? query
      yield @hash[query]
      return
    end

    case query
    when String
      optimize_if_necessary!
      @regexes.each do |regex|
        if match = regex.match(query)
          @regex_counts[regex] += 1
          value = @hash[regex]
          if value.responds_to? :call
            yield value.call(match)
          else
            yield value
          end
        end
      end

    when Integer
      @ranges.each do |range|
        yield @hash[range] if range.include? query
      end

    when Regexp
      # TODO: this doesn't seem very useful. should I ditch it? let me know!
      @hash.each do |key,val|
        yield val if key.is_a? String and query =~ key
      end

    end

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

