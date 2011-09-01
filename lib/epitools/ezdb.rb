require 'epitools'
require 'dbm'
require 'delegate'

class Ezdc < DelegateClass(Hash)

  attr_reader :db, :path, :dirty

  @@dirty = Set.new
  
  def initialize(filename)
    @path = Path[filename]
    
    if @path.ext.nil?
      @path.ext = "db"
    else
      @path.ext += ".db" if @path.ext != 'db'
    end
    
    @db = DBM::open(@path.with(:ext=>nil))
    
    super
  end
  
  class Observed < BasicObject
    MUTATORS = ::Set.new [
      :<<, :push, :pop, :slice, :[]=
    ]
  
    def __send__(meth, *args)
      if MUTATORS.include? meth
        @@dirty.add self
      end
      
    end
  end
  
  def observed(obj)
    obj.using(Observed)
  end
  
  def [](key)
    observed(super[key])
  end
  
  def []=(key, val)
  end
  
  def keys
    db.keys.map(&:unmarshal)
  end
  
  def delete!
    @path.rm
  end
  
  def flush!
    dirty.each do |key|
      db[key.marshal] = super[key].marshal
    end
  end
  
end


class Ezdb

  attr_reader :db, :path

  def initialize(filename)
    @path = Path[filename]
    
    if @path.ext.nil?
      @path.ext = "db"
    else
      @path.ext += ".db" if @path.ext != 'db'
    end
    
    @db = DBM::open(@path.with(:ext=>nil))
  end
  
  def [](key)
    val = db[key.marshal]
    val = val.unmarshal if val
    val
  end
  
  def []=(key, val)
    db[key.marshal] = val.marshal
  end
  
  def keys
    db.keys.map(&:unmarshal)
  end
  
  def delete!
    @path.rm
  end
  
end
