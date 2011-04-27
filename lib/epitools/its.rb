
module Kernel

  protected

  #
  # Magic "its" Mapping
  # -------------------
  #
  # The pure-Ruby way:
  #   User.find(:all).map{|x| x.contacts.map{|y| y.last_name.capitalize }}
  #
  # With Symbol#to_proc:
  #   User.find(:all).map{|x|x.contacts.map(&:last_name).map(&:capitalize)}
  #
  # Magic "its" way:
  #   User.find(:all).map &its.contacts.map(&its.last_name.capitalize)
  #
  def it()
    It.new
  end

  alias its it

end


class It < BasicObject # :nodoc:
  #undef_method( *(instance_methods - ["__id__", "__send__"]) )

  def initialize
    @methods = []
  end

  def method_missing(*args, &block)
    @methods << [args, block] unless args == [:respond_to?, :to_proc]
    self
  end

  def to_proc
    lambda do |obj|
      @methods.inject(obj) do |current,(args,block)|
        current.send(*args, &block)
      end
    end
  end
end

