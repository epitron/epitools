#
# Like a Stuct, but automatically casts input to specific types.
#
# Example:
#
#   class SomeRecord < TypedStruct["some_id:int amount:float x:string a,b,c:bool"]; end
#   record = SomeRecord.new(69, 12348.871, "stringy", true, 1, "no")
#
class TypedStruct < Struct

  ## TODO: Compact syntax: "a,b,c:int x:string y:date"
  ## TODO: Optional commas separating fields: "a, b, c:int, d:bool"
  ## TODO: booleans fields add "field?" methods

  #
  # A perhaps-too-clever table of { "typename" => convert_proc } mappings.
  #
  CONVERTERS = Hash[ *{
    ["str", "string"]            => :passthru,
    ["int", "integer"]           => proc { |me| me.to_i },
    ["hex"]                      => proc { |me| me.to_i(16) },
    ["date", "time", "datetime"] => proc { |me| DateTime.parse me },
    ["timestamp"]                => proc { |me| Time.at me },
    ["bool", "boolean"]          => proc do |me| 
      case me
      when false, 0, "0", "off", "no",  "false", nil
        false
      when true,  1, "1", "on",  "yes", "true"
        true
      else
        raise "Invalid boolean type: #{me.inspect}"
      end
    end
  }.map { |names, converter| names.map { |n| [n, converter] } }.flatten ]

  #
  # Initialize a new struct.
  #
  def self.[](specs)
    # create [name,type] pairs
    pairs = specs.split.map do |spec|
      name, type = spec.split(":")

      type ||= "string"
      unless converter = CONVERTERS[type]
        raise "Unknown type: #{type}"
      end

      [name.to_sym, converter]
    end

    # initialize the C Struct
    struct = new(*pairs.transpose.first)

    # overload setter methods to call the proc
    pairs.each do |field, converter| 
      next if converter == :passthru
      struct.send(:define_method, "#{field}=") do |val|
        self[field] = ( val and converter.call val )
      end
    end

    struct
  end

  def initialize(*args)    
    members.zip(args).each { |field,value| send "#{field}=", value }
  end

end
