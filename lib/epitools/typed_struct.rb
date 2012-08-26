#
# Like a Stuct, but automatically casts assignments to specific types.
#
# Example:
#
#   class SomeRecord < TypedStruct["some_id:int amount:float name:string a,b,c:bool untyped_var"]
#   end
#
#   record = SomeRecord.new(69, 12348.871, "stringy", true, 1, "no", Object.new)
#
#   another_record = SomeRecord.new :amount=>"1.5", :name=>"Steve", :c=>"true", :a=>"disable", :untyped_var=>Ratio.new(1/2)
#   record.amount *= 3.141592653589793238462643383279
#
# Recognized types, and what they get converted into:
#
#   <no type given>              => Don't enforce a type -- any ruby object is allowed.
#   ["str", "string"]            => String
#   ["int", "integer"]           => Integer
#   ["float"]                    => Float
#   ["bigdecimal"]               => BigDecimal
#   ["hex"]                      => Integer
#   ["date", "time", "datetime"] => DateTime (using DateTime.parse)
#   ["timestamp", "unixtime"]    => Time (using Time.at) 
#   ["bool", "boolean"]          => Boolean, using the following rules:
#                                    false when: false, nil, 0, "0", "off", "no", 
#                                                "false", "disabled", "disable"
#                                     true when: true, 1, "1", "on",  "yes", 
#                                                "true", "enabled", "enable"
#
class TypedStruct < Struct

  ## TODO: Compact syntax: "a,b,c:int x:string y:date"
  ## TODO: Optional commas separating fields: "a, b, c:int, d:bool"
  ## TODO: booleans fields add "field?" methods
  ## TODO: default values: "a:int(default=50)" or "b:int(50)"

  #
  # A perhaps-too-clever table of { "typename" => convert_proc } mappings.
  #
  CONVERTERS = Hash[ *{
    [:passthru]                  => :passthru,
    ["str", "string"]            => proc { |me| me.to_s },
    ["int", "integer"]           => proc { |me| me.to_i },
    ["float"]                    => proc { |me| me.to_f },
    ["bigdecimal"]               => proc { |me| BigDecimal.new me },
    ["hex"]                      => proc { |me| me.to_i(16) },
    ["date", "time", "datetime"] => proc { |me| DateTime.parse me },
    ["timestamp", "unixtime"]    => proc { |me| Time.at me },
    ["bool", "boolean"]          => proc do |me| 
      case me
      when false, nil, 0, "0", "off", "no",  "false", "disabled", "disable"
        false
      when true,  1, "1", "on",  "yes", "true", "enabled", "enable"
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

      type ||= :passthru

      unless converter = CONVERTERS[type]
        raise "Unknown type: #{type}"
      end

      [name.to_sym, converter]
    end

    # initialize the Struct
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
    if args.size == 1 and args.first.is_a? Hash
      opts = args.first
    else
      opts = Hash[members.zip(args)]
    end

    opts.each { |key,value| send "#{key}=", value }
  end

end
