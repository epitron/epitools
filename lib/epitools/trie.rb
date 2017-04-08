#!/usr/bin/ruby -w
#
# = Name
# Trie
#
# == Description
# This file contains an implementation of a trie data structure.
#
# == Version
# 0.0.1
#
# == Author
# Daniel Erat <dan-ruby@erat.org>
#
# == Copyright
# Copyright 2005 Daniel Erat
#
# == License
# GNU GPL; see COPYING
#
# == Changes
# 0.0.1  Initial release



# = Trie
#
# == Description
# Implementation of a trie data structure, well-suited for storing and
# looking up strings or other sequences.
#
# More specifically, this is an implementation of a Patricia trie
# (http://en.wikipedia.org/wiki/Patricia_trie).
#
# == Usage
#  require "trie"
#
#  # Create a new Trie and insert some values into it.
#  t = Trie.new
#  t.insert("the", 1)
#  t.insert("they", 2)
#  t.insert("they", 3)
#  t.insert("their", 4).insert("they're", 5)
#
#  # Search for an exact match of "they".
#  t.find("they").values  # => [2, 3]
#
#  # Search for a prefix that will match all keys.
#  t2 = t.find_prefix("th")
#  puts t2.size  # prints 5
#
#  # In the sub-Trie beginning with "th", search for the prefix "ey"
#  # (therefore, getting the three values with keys beginning with "they").
#  t2.find_prefix("ey").each_value {|v| puts v }  # prints 2, 3, and 5
#
#  # Now search for "at" in the sub-Trie, which results in an empty Trie
#  # (as there are no keys beginning with "that").
#  puts t2.find_prefix("at").empty?  # prints true
#
#  # Delete all values keyed by "they" (note that this must be performed on
#  # the root Trie rather than the one returned by Trie.find_prefix -- read
#  # the "Notes" section to find out why).
#  t.delete("they")
#
# == Notes
# Keys are stored internally as Arrays.  If you use Strings as keys they
# will be automatically converted, and when you use a method to access them
# later you'll receive them as Arrays instead.  For example:
#
#  t = Trie.new.insert("abc", 1).insert("def", 2)
#  t.keys                        # => [["a", "b", "c"], ["d", "e", "f"]]
#  t.keys.collect {|k| k.join }  # => ["abc", "def"]
#
# (I'm hesitant to add code that will return keys as Strings if the user
# has only passed in Strings so far.)
#
# Empty nodes are compressed.  The strings "row" and "ruby", which would
# normally be stored as
#
#       ''
#       /
#      r
#     / \
#    o   u
#   /     \
#  w       b
#           \
#            y
#
# are actually stored as
#
#      ''
#      /
#     r
#    / \
#  ow  uby
#
# Because of this implementation (and to allow Trie.find to be called on
# nodes returned by Trie.find that contain compressed elements), Trie.find
# and Trie.find_prefix will in some (most) cases return Trie objects that
# are not members of the root Trie.  As a result, methods such as
# Trie.insert, Trie.delete, and Trie.clear should only be called on Trie
# objects that were directly returned by Trie.new.
class Trie
  include Enumerable

  ##
  # Create a new empty Trie.
  #
  # ==== Example
  #  t = Trie.new  # gasp!
  #
  def initialize
    @values = Set.new
    @children = {}
    @compressed_key = []
    @compressed_values = Set.new
  end

  ##
  # Return all of the items matching a key.
  #
  # ==== Example
  #  t = Trie.new.insert("a", 3).insert("a", 4).insert("b", 5)
  #  t["a"]  # => [3, 4]
  #
  def [](key)
    find(key).values
  end

  ##
  # Clear the trie.
  #
  # ==== Example
  #  t = Trie.new.insert("blah", 3).insert("a", 1)
  #  t.clear  # t now contains no values
  #
  def clear
    @values.clear
    @children.clear
    @compressed_key.clear
    @compressed_values.clear
    self
  end

  ##
  # Delete all values with a given key.
  #
  # ==== Example
  #  t = Trie.new.insert("a", 1).insert("a", 2).insert("abc", 3)
  #  t.delete("a")  # t now only contains the third value
  #
  def delete(key)
    key = key.split('') if key.is_a?(String)
    if key.empty?
      @values.clear
    elsif key == @compressed_key
      @compressed_key.clear
      @compressed_values.clear
    elsif @children[key[0]]
      @children[key[0]].delete(key[1..-1])
      @children.delete(key[0]) if @children[key[0]].empty?
    end
    self
  end

  ##
  # Delete all occurences of an value.
  #
  # ==== Example
  #  t = Trie.new.insert("a", 1).insert("blah", 1).insert("a", 2)
  #  t.delete_value(1)  # t now only contains the third value
  #
  def delete_value(value)
    @compressed_values.delete(value)
    @compressed_key.clear if @compressed_values.empty?
    @values.delete(value)
    @children.each do |p, t|
      t.delete_value(value)
      @children.delete(p) if t.empty?
    end
    self
  end

  ##
  # Delete a (key, value) pair.
  #
  # ==== Example
  #  t = Trie.new.insert("a", 1).insert("a", 2)
  #  t.delete_pair("a", 1)  # t now only contains the second value
  #
  def delete_pair(key, value)
    key = key.split('') if key.is_a?(String)
    if key.empty?
      @values.delete(value)
    elsif key == @compressed_key
      @compressed_values.delete(value)
      @compressed_key.clear
    elsif @children[key[0]]
      @children[key[0]].delete_pair(key[1..-1], value)
      @children.delete(key[0]) if @children[key[0]].empty?
    end
    self
  end

  ##
  # Delete all values keyed by a given prefix.
  #
  # ==== Example
  #  t = Trie.new.insert("a", 1).insert("al", 2).insert("algernon", 3)
  #  t.delete_prefix("al")  # t now only contains the first value
  #
  def delete_prefix(prefix)
    prefix = prefix.split('') if prefix.is_a?(String)
    if prefix.empty? or prefix == @compressed_key[0...prefix.size]
      clear
    elsif @children[prefix[0]]
      @children[prefix[0]].delete_prefix(prefix[1..-1])
      @children.delete(prefix[0]) if @children[prefix[0]].empty?
    end
    self
  end

  ##
  # Calls block once for each (key, value) pair in the Trie, passing
  # the the key and value as parameters.
  #
  # ==== Example
  #  t = Trie.new.insert("a", 1).insert("b", 2)
  #  t.each {|k, v| puts "#{k.join()}: #{v} }  # prints "a: 1" and "b: 2"
  #
  def each(prefix=[])
    @values.each {|v| yield(prefix, v) }
    @compressed_values.each {|v| yield(prefix.dup.concat(@compressed_key), v) }
    @children.each do |k, t|
      t.each(prefix.dup.push(k)) {|key, value| yield(key, value) }
    end
    self
  end

  ##
  # Calls block once for each key in the Trie, passing the key as a
  # parameter.
  #
  # ==== Example
  #  t = Trie.new.insert("abc", 1).insert("def", 2)
  #  t.each_key {|key| puts key.join() }  # prints "abc" and "def"
  #
  def each_key(prefix=[])
    yield prefix if not @values.empty?
    yield prefix.dup.concat(@compressed_key) if not @compressed_values.empty?
    @children.each do |k, t|
      t.each_key(prefix.dup.push(k)) {|key| yield key }
    end
    self
  end

  ##
  # Calls block once for each (key, value) pair in the Trie, passing
  # the value as a parameter.
  #
  # ==== Example
  #  t = Trie.new.insert("a", 1).insert("b", 2)
  #  t.each_value {|value| puts value }  # prints "1" and "2"
  #
  def each_value
    @compressed_values.each {|value| yield value }
    @values.each {|value| yield value }
    @children.each_value {|t| t.each_value {|value| yield value } }
    self
  end

  ##
  # Does this Trie contain no values?
  #
  # ==== Example
  #  t = Trie.new
  #  t.empty?  # => true
  #  t.insert("blah", 1)
  #  t.empty?  # => false
  #
  def empty?
    size == 0
  end

  ##
  # Get a new Trie object containing all values with the passed-in key.
  #
  # ==== Example
  #  t = Trie.new.insert("the", 1).insert("their", 2).insert("foo", 4)
  #  t.find("the")  # => Trie containing the only first value
  #
  def find(key)
    key = key.split('') if key.is_a?(String)
    if (key.empty? and @compressed_key.empty?) or key == @compressed_key
      trie = Trie.new
      @values.each {|v| trie.insert([], v) }
      @compressed_values.each {|v| trie.insert([], v) }
      trie
    elsif @children[key[0]]
      @children[key[0]].find(key[1..-1])
    else
      Trie.new
    end
  end

  ##
  # Get a new Trie object containing all values with keys that begin with
  # the passed-in prefix.
  #
  # ==== Example
  #  # Both calls return a Trie containing only the first value:
  #  t = Trie.new.insert("test", 1).insert("testing", 2)
  #  t.find_prefix("test")
  #  t.find_prefix("").find("t").find("es").find("t").find("")
  #
  def find_prefix(prefix)
    prefix = prefix.split('') if prefix.is_a?(String)
    if prefix.empty?
      self
    elsif prefix == @compressed_key[0...prefix.size]
      trie = Trie.new
      @compressed_values.each do |value|
        trie.insert(@compressed_key[prefix.size..-1], value)
      end
      trie
    elsif @children[prefix[0]]
      @children[prefix[0]].find_prefix(prefix[1..-1])
    else
      Trie.new
    end
  end

  ##
  # Insert an value into this Trie, keyed by the passed-in key,
  # which can be any sort of indexable object.
  #
  # ==== Example
  #  t = Trie.new.insert("this is a string of considerable length", [ 0, 4, ])
  #  t.insert([ "abc", "def", ], "testing")
  #
  def insert(key, value)
    key = key.split('') if key.is_a?(String)
    if key != @compressed_key
      @compressed_values.each {|v| insert_in_child(@compressed_key, v) }
      @compressed_values.clear
      @compressed_key.clear
    end

    if key.empty?
      @values.add(value)
    elsif (@values.empty? and @children.empty?) or key == @compressed_key
      @compressed_key = key.dup
      @compressed_values.add(value)
    else
      insert_in_child(key, value)
    end
    self
  end

  ##
  # Insert an value into a sub-Trie, creating one if necessary.
  #
  # Internal method called by Trie.insert.
  #
  def insert_in_child(key, value)
    (@children[key[0]] ||= Trie.new).insert(key[1..-1], value)
  end
  private :insert_in_child

  ##
  # Get an Array containing all keys in this Trie.
  #
  # ==== Example
  #  t = Trie.new.insert("test", 1).insert([0, 1], 2)
  #  t.keys  # => [['t', 'e', 's', 't'], [0, 1]]
  #
  def keys
    a = []
    each_key {|key| a.push(key) }
    a
  end

  ##
  # Get the number of nodes used to represent this Trie.
  #
  # This is only useful for testing.
  #
  def num_nodes
    node_count = 1
    @children.each {|p, t| node_count += t.num_nodes }
    node_count
  end

  ##
  # Get the number of values contained in this Trie.
  #
  # ==== Example
  #  t = Trie.new.insert("test", 1).insert("foo", 2)
  #  t.size  # => 2
  #
  def size
    child_count = 0
    @children.each_value {|t| child_count += t.size }
    @compressed_values.size + @values.size + child_count
  end

  ##
  # Get an Array containing all values in this Trie.
  #
  # ==== Example
  #  t = Trie.new.insert("a", 1).insert("b", 2)
  #  t.values  # => Array containing both values
  #  t.values.each {|value| puts value }  # prints "1" and "2"
  #
  def values
    a = []
    each_value {|value| a.push(value) }
    a
  end

end  # class Trie
