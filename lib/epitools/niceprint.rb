def niceprint(o, level=0, indent_first_line=true)
  maxstring = 50
  maxarray = 20

  result = ""

  dent = "    "
  indent = dent * level

  result << indent if indent_first_line

  case o

    when Hash
      #puts "Hash!"
      result << "{\n"

      o.each_with_index do |(k,v),i|
        result << "#{indent+dent}#{k.inspect} => #{niceprint(v,level+1,false)}"
        result << "," unless i == o.size
        result << "\n"
      end

      result << "#{indent}}"

    when Array
      #puts "Array!"
      indent_first = o.any? { |e| e.instance_of? Hash }

      if indent_first
        result << "[\n"
      else
        result << "["
      end

      o = o[0..maxarray] if o.size > maxarray
      o.each do |e|
        result << niceprint(e,level+1,indent_first)
        result << ", "
      end

      result << "]"

    when String
      #puts "String!"
      o = o[0..maxstring] + "..." if o.size > maxstring
      result << o.inspect

    else
      result << o.inspect
  end

  if level == 0
    print result
  else
    result
  end

end

if $0 == __FILE__
  t = {
    :a => 5,
    :b => 10,
    :c => {
      :x => 10,
      :y => [1,2,3,4,5,6,7],
    },
    :d => "asdf"*1000,
  }

  puts niceprint(t)
end
