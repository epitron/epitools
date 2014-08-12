
class Hash

  #
  # 'true' if the Hash has no entries
  #
  def blank?
    not any?
  end
  
  #
  # Runs "remove_blank_values" on self.
  #  
  def remove_blank_values!
    delete_if{|k,v| v.blank?}
    self
  end
  
  #
  # Returns a new Hash where blank values have been removed.
  # (It checks if the value is blank by calling #blank? on it)
  #
  def remove_blank_values
    dup.remove_blank_values!
  end
  
  #
  # Runs map_values on self. 
  #  
  def map_values!(&block)
    keys.each do |key|
      value = self[key]
      self[key] = yield(value)
    end
    self
  end
  
  #
  # Transforms the values of the hash by passing them into the supplied
  # block, and then using the block's result as the new value.
  #
  def map_values(&block)
    dup.map_values!(&block)
  end

  #
  # Runs map_keys on self.
  #  
  def map_keys!(&block)
    keys.each do |key|
      value = delete(key)
      self[yield(key)] = value
    end
    self
  end
  
  #
  # Transforms the keys of the hash by passing them into the supplied block,
  # and then using the blocks result as the new key.
  #
  def map_keys(&block)
    dup.map_keys!(&block)
  end

  #
  # Returns a hash containing only the keys passed as arguments.
  #
  def slice(*keys)
    dup.slice!(*keys)
  end


  #
  # Alters the hash so it contains only the keys passed as arguments.
  #
  def slice!(*keys)
    keys = Set.new keys
    delete_if { |k,v| not keys.include? k }
    self
  end

  #
  # Returns a new Hash whose values default to empty arrays. (Good for collecting things!)
  #
  # eg:
  #   Hash.of_arrays[:yays] << "YAY!"
  #
  def self.of_arrays
    new {|h,k| h[k] = [] }
  end

  #
  # Returns a new Hash whose values default to empty sets. (Good for collecting unique things!)
  #
  # eg:
  #   Hash.of_sets[:yays] << "Yay!"
  #
  def self.of_sets
    new {|h,k| h[k] = Set.new }
  end

  #
  # Returns a new Hash whose values default to 0. (Good for counting things!)
  #
  # eg:
  #   Hash.of_integers[:yays] += 1
  #
  def self.of_integers
    new(0)
  end

  #
  # Returns a new Hash which automatically assigns each unique key to an increasing counter.
  #
  # eg:
  #   > h = Hash.of_unique_ids
  #   => {}
  #   > h["Person"]               #=> 0
  #   > h["Another Person"]       #=> 1
  #   > h["Yet Another Person"]   #=> 2
  #   > h["Person"]               #=> 0
  #   > h
  #   => {"Person"=>0, "Another Person"=>1, "Yet Another Person"=>2}
  #
  def self.of_unique_ids
    new { |h,k| h[k] = h.size }
  end

  #
  # Hash keys become methods, kinda like OpenStruct. These methods have the lowest priority,
  # so be careful. They will be overridden by any methods on Hash.
  #
  def self.lazy!
    Hash.class_eval do
      def method_missing(name, *args)
        if args.any?
          super
        else
          self[name] || self[name.to_s]
        end
      end
    end
  end  
  
  #
  # `key?` and `includes?` is an alias for `include?`
  #  
  alias_method :key?,       :include?
  alias_method :includes?,  :include?
  
  #
  # Makes each element in the `path` array point to a hash containing the next element in the `path`.
  # Useful for turning a bunch of strings (paths, module names, etc.) into a tree.
  #
  # Example:
  #   h = {}
  #   h.mkdir_p(["a", "b", "c"])    #=> {"a"=>{"b"=>{"c"=>{}}}}
  #   h.mkdir_p(["a", "b", "whoa"]) #=> {"a"=>{"b"=>{"c"=>{}, "whoa"=>{}}}}
  #
  def mkdir_p(path)
    return if path.empty?
    dir = path.first
    self[dir] ||= {}
    self[dir].mkdir_p(path[1..-1])
    self
  end
  
  #
  # Turn some nested hashes into a tree (returns an array of strings, padded on the left with indents.)
  #
  def tree(level=0, indent="  ")
    result = []
    dent = indent * level
    each do |key, val|
      result << dent+key
      result += val.tree(level+1) if val.any?
    end
    result
  end  
  
  #
  # Print the result of `tree`
  #
  def print_tree
    tree.each { |row| puts row }
    nil
  end  
  
  #
  # Convert the hash into a GET query.
  #
  def to_query
    params = ''
    stack = []
  
    each do |k, v|
      if v.is_a?(Hash)
        stack << [k,v]
      else
        params << "#{k}=#{v}&"
      end
    end
  
    stack.each do |parent, hash|
      hash.each do |k, v|
        if v.is_a?(Hash)
          stack << ["#{parent}[#{k}]", v]
        else
          params << "#{parent}[#{k}]=#{v}&"
        end
      end
    end
  
    params.chop! # trailing &
    params
  end
  
  #
  # Query a hash using MQL (see: http://wiki.freebase.com/wiki/MQL_operators for reference)
  #
  # Examples: 
  #   > query(name: /steve/)
  #   > query(/title/ => ??)
  #   > query(articles: [{title: ??}])
  #   > query(responses: [])
  #   > query("date_of_birth<" => "2000")
  #
  def query(template)
    results = [] 
    template.each do |key,val|
      case key
      when Regexp, String
      when Array
      when Hash
        results += hash.query(template)  
      end
    end
    
    map do |key,val|
    end    
  end
  alias_method :mql, :query
  

  #
  # Return all the changes necessary to transform `self` into `other`. (Works on nested hashes.) The result is a hash of {:key => [old value, new value]} pairs.
  #
  # (NOTE: Since "nil" is used to denote a value was removed, you can't use this method to diff hashes where a value is "nil".)
  #
  def diff(other)
    (self.keys + other.keys).uniq.inject({}) do |memo, key|
      unless self[key] == other[key]
        if self[key].kind_of?(Hash) && other[key].kind_of?(Hash)
          memo[key] = self[key].diff(other[key])
        else
          memo[key] = [self[key], other[key]] 
        end
      end
      memo
    end
  end

  #
  # Applies a Hash#diff changeset to this hash.
  #
  def apply_diff!(changes)
    path = [[self, changes]]
    pos, local_changes = path.pop

    while local_changes
      local_changes.each_pair do |key, change|
        if change.kind_of?(Array)
          if change[1].nil?
            pos.delete key
          else
            pos[key] = change[1]
          end
        else
          path.push([pos[key], change])
        end
      end

      pos, local_changes = path.pop
    end

    self
  end

  #
  # Applies a Hash#diff changeset and returns the transformed hash.
  #
  def apply_diff(changes)
    deep_dup.apply_diff!(changes)
  end

  #
  # Duplicate this hash, including hashes nested inside of it.
  #
  def deep_dup
    duplicate = self.dup
    duplicate.each_pair do |k,v|
      tv = duplicate[k]
      duplicate[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? tv.deep_dup : v
    end
    duplicate
  end

end

