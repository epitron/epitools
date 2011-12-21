require 'epitools'

describe Object do

  it "has Enum" do
    defined?(Enum).should_not == nil
  end
  
  #it "enums" do
  #  generator = enum { |y| y.yield 1 }
  #  generator.next.should == 1
  #end

  it "withs" do
    class Cookie; attr_accessor :size, :chips; end
    
    c = Cookie.new; c.size = 10; c.chips = 200
    w = c.with(:chips=>50)
    
    w.size.should == c.size
    w.chips.should_not == c.chips
    w.should_not === c
  end
  
  it "in?" do
    5.in?([1,2,3,4,5,6]).should == true
    5.in?(1..10).should == true
    5.in?(20..30).should == false
    "butt".in?("butts!!!").should == true
  end
 
  it "times" do
    lambda { 
      time("time test") { x = 10 }
    }.should_not raise_error

    lambda { 
      time("time test") { raise "ERROR" }
    }.should raise_error
  end
  
  it "benches" do
    lambda { bench { rand }                 }.should_not raise_error
    lambda { bench(20) { rand }             }.should_not raise_error
    lambda { bench                          }.should raise_error
    lambda { bench(:rand => proc { rand }, :notrand => proc { 1 })        }.should_not raise_error
    lambda { bench(200, :rand => proc { rand }, :notrand => proc { 1 })   }.should_not raise_error
  end

  it "trys" do
    s = Struct.new(:a,:b).new
    s.a = 5
    s.b = 10
    
    s.try(:a).should == 5 
    s.try(:b).should == 10
    s.try(:c).should == nil
    
    lambda { s.try(:c) }.should_not raise_error
    lambda { s.c }.should raise_error

    def s.test(a); a; end
    
    s.test(1).should == 1
    s.try(:test, 1).should == 1
    
    lambda { s.test }.should raise_error
    lambda { s.try(:test) }.should raise_error
    
    def s.blocky; yield; end

    s.blocky{ 1 }.should == 1
    s.try(:blocky){ 1 }.should == 1
    s.try(:nonexistant){ 1 }.should == nil
  end
  
  it "nots" do
    10.even?.should == true
    10.not.even?.should == false
  end
  
  it "alias_class_methods" do
    class Blah
      def self.classmethod
        true
      end
      
      alias_class_method :aliased, :classmethod
    end
    
    lambda do 
      Blah.classmethod.should == true
    end.should_not raise_error
    
  end

  it "marshals/unmarshals" do
    :whee.marshal.unmarshal.should == :whee
    :whee.marshal.should == Marshal.dump(:whee)
  end
    
  
end


describe Class do
  
  it "uses" do
    module Test1
      def test1; :test1; end
    end
    
    module Test2
      def test2; :test2; end
    end
    
    Hash.using(Test1).new.test1.should == :test1
    Hash.using(Test2).new.test2.should == :test2
    h = Hash.using(Test1, Test2).new
    h.test1.should == :test1
    h.test2.should == :test2
    
    Hash.using(Test1) do |h|
      h.new.test1.should == :test1
    end    
  end
  
end


describe Numeric do

  it "commatizes" do
    123.commatize.should == "123"
    1234.commatize.should == "1,234"
    12983287123.commatize.should == "12,983,287,123"
    -12983287123.commatize.should == "-12,983,287,123"
    -12983287123.4411.commatize.should == "-12,983,287,123.4411"
  end
  
  it "does time things" do
    1.second.should == 1
    1.minute.should == 60
    2.minutes.should == 120
    2.hours.should == 120*60
    2.5.days.should == 3600*24*2.5
    
    5.days.ago.to_i.should == (Time.now - 5.days).to_i
    1.year.ago.year.should == Time.now.year - 1 
    5.days.from_now.to_i.should == (Time.now + 5.days).to_i
  end
  
end


describe String do
  
  it "rot13s" do
    message = "Unbreakable Code"
    message.rot13.should_not == message
    message.rot13.rot13.should == message
  end
  
  it "tightens" do
    " hi   there".tighten.should == "hi there"
  end
  
  it "dewhitespaces" do
    "\nso there   i \n was, eating my cookies".dewhitespace.should == "so there i was, eating my cookies"
  end
  
  it "nice_lineses" do
    "\n\n\nblah\n\n\nblah\n\n\n".nice_lines.should == ["blah", "blah"]    
  end
  
  it "strips color" do
    s = "woot!"
    color_s = s.light_green
    color_s.strip_color.should == s  
  end
  
  it "urlencodes/decodes" do
    s = "hi + there & mom + !!!!! I AM ON RSPEC"
    s.urlencode.should_not == s
    s.urlencode.should == "hi%20+%20there%20&%20mom%20+%20!!!!!%20I%20AM%20ON%20RSPEC"
    s.urlencode.urldecode.should == s
  end
  
  it "to_paramses" do
    "file=yay&setting=1&awesome=true".to_params.should == {"file" => "yay", "setting"=>"1", "awesome"=>"true"}
  end
  
  it "md5/sha1s" do
    s = "hashme"
    s.md5.should_not == s
    s.sha1.should_not == s
    s.sha1.should_not == s.md5
  end
  
  it "gzips/gunzips/delfates/inflates" do
    s = "asdklfjasdfjaeh"
    s.deflate.should_not == s
    s.deflate.inflate.should == s

    s.gzip.should_not == s
    s.gzip.gunzip.should == s
    
    s.gzip(9).size.should < s.gzip(0).size
    s.deflate(9).size.should < s.deflate(0).size
  end

  it "starts/endswith" do
    "blahblahblah".startswith("blah").should == true    
    "blahblahblah".endswith("blah").should == true    
  end

  it "amounts" do
    "cookie".amount(5).should == "5 cookies"
    "cookie".amount(0).should == "0 cookies"
    "shirt".amount(17).should == "17 shirts"
    "dollar".amount(-10).should == "-10 dollars"
    "love".amount(1).should == "1 love"
  end
  
end


describe Integer do
  
  it "integer?" do
    
    {
      true  => [ "123", "000", 123, 123.45 ],
      false => [ "123asdf", "asdfasdf", Object.new, nil ]
    }.each do |expected_result, objects|
      objects.each { |object| object.integer?.should == expected_result }
    end
    
  end
  
  it "has bits" do
    1.to_bits.should == [1]
    2.to_bits.should == [0,1]
    3.to_bits.should == [1,1]
    42.to_bits.should == [0,1,0,1,0,1]
    
    # round trip
    20.times do
      n = rand(918282393982)
      n.to_bits.reverse.join.to_i(2).should == n
    end
  end
  
  it "slices into bits" do
    i = "111011".to_i(2) 
    # Note: to_i(2) accepts big-endian, while the Fixnum#[] slicing will return little endian. 
    #       So make sure to reverse the bit string for the specs.

    i[0].should == 1
    i[2].should == 0
    
    i[0..2].should == [1,1,0]
    i[-3..-1].should == [1,1,1]
    i[0..-1].should == [1,1,0,1,1,1]
  end

  it "converts to/from base62" do
    Integer::BASE62_BASE.should == 62
  
    [1,20,500,501,34191923].each do |n|
      n.to_base62.from_base62.should == n
    end
    
    sum = "asdf".md5
    sum.to_base62.from_base62.to_s(16).should == sum
  end
  
  it "factors numbers" do
    10.factors.should == [2,5]
    256.factors.should == [2,2,2,2,2,2,2,2]
  end
  
end


describe Array do
  
  it "squashes" do
    [1,2,[3,4,[5],[],[nil,nil],[6]]].squash.should == [1,2,3,4,5,6]
  end
  
  it "remove_ifs" do
    nums = [1,2,3,4,5,6,7,8,9,10,11,12]
    even = nums.remove_if { |n| n.even? }   # remove all even numbers from the "nums" array and return them
    odd = nums         
    
    even.should == [2,4,6,8,10,12]
    odd.should == [1,3,5,7,9,11]
  end
  
  it "rzips" do
    [5,39].rzip([:hours, :mins, :secs]).should == [ [5, :mins], [39, :secs] ]
  end
  
  it "middles" do
    a = [0,1,2,3,4,5]
    a.middle.should == 2
    a << 6
    a.middle.should == 3
  end
  
  it "/'s" do
    a = [1,2,3,4,5]
    b = [1,2,3,4]

    # splits?
    (a/2).should == [[1,2,3],[4,5]]
    (a/3).should == [[1,2],[3,4],[5]]
    
    (b/2).should == [[1,2],[3,4]] 
  end
  
  it "includes?s" do
    [:a, :b, :c].includes?(:c).should == true
    [:a, :b, :c].includes?(5).should == false
  end
  
end


describe Enumerable do

  it "splits" do
    [1,2,3,4,5].split_at     {|e| e == 3}.should == [ [1,2], [4,5] ]
    [1,2,3,4,5].split_after  {|e| e == 3}.should == [ [1,2,3], [4,5] ]
    [1,2,3,4,5].split_before {|e| e == 3}.should == [ [1,2], [3,4,5] ]

    "a\nb\n---\nc\nd\n".lines.split_at(/---/).map_recursively(&:strip).should   == [ %w[a b], %w[c d] ]
  end

  it "handles nested things" do
    array = [ [],["a"],"a",[1,2,3] ]

    lambda { 
      array.split_at("a")
    }.should_not raise_error
    
    array.split_at("a").should     == [ array[0..1], array[3..3] ] 
    array.split_at([1,2,3]).should == [ array[0..2] ]
  end
  
  it "handles arbitrary objects" do
    arbitrary = Struct.new(:a, :b, :c)
    
    particular = arbitrary.new(1,2,3)
    array = [ arbitrary.new, arbitrary.new, particular, arbitrary.new]
    
    array.split_at(particular).should == [ array[0..1], array[3..3] ]    
  end
  
  it "sums" do
    [1,2,3,4,5].sum.should == 15
  end
  
  it "averages" do
    [1,3].average.should == 2.0
    [1,1,3,3].average.should == 2.0
  end

  it "maps deeply" do
    [[1,2],[3,4]].deep_map {|e| e ** 2}.should == [[1,4],[9,16]] 
    [1,2,3,4].deep_map {|e| e ** 2}.should == [1,4,9,16] 
    [[],[],1,2,3,4].deep_map {|e| e ** 2}.should == [[], [], 1, 4, 9, 16] 
  end
  
  it "selects deeply" do
    [[1,2],[3,4]].deep_select {|e| e % 2 == 0 }.should == [2,4] 
    {1=>2, 3=>{4=>5, 6=>7}}.deep_select {|k,v| k == 1 }.should == {1=>2} 
    #[1,2,3,4].deep_select {|e| e ** 2}.should == [1,4,9,16] 
    #[[],[],1,2,3,4].deep_select {|e| e ** 2}.should == [[], [], 1, 4, 9, 16] 
  end
  
  it "foldl's" do
    a = [1,2,3,4]
    a.foldl(:+).should == a.sum
    %w[hi there].foldl(:+).should == "hithere"

    [ [1],[2],[3],[4] ].foldl(:+).should == [1,2,3,4] 
  end
  
  it "powersets" do
    [1,2,3].powerset.should == [[], [1], [2], [1, 2], [3], [1, 3], [2, 3], [1, 2, 3]]
    Enum.new([1,2], :each).powerset.should == [[], [1], [2], [1, 2]]
  end
  
  it "unzips" do
    [ [:a, 1], [:b, 2] ].unzip.should == [ [:a, :b], [1, 2] ]
  end
  
  it "group_neighbours_bys" do
    a = [1,2,5,6,7,10,11,13]
    result = a.group_neighbours_by { |a,b| b-a <= 1 }
    result.should == [[1,2],[5,6,7],[10,11],[13]]
  end
  
  it "includes?s" do
    [:a, :b, :c].to_enum.includes?(:c).should == true
    [:a, :b, :c].to_enum.includes?(5).should == false
  end
  
end

describe Hash do

  before :each do
    @h = {"key1"=>"val1", "key2"=>"val2"}
  end
    
  it "maps keys" do
    h = @h.map_keys{|k| k.upcase}
    h.keys.should == @h.keys.map{|k| k.upcase}
    h.values.should == @h.values
    
    h.map_keys! { 1 }
    h.keys.should == [1]
  end
  
  it "maps values" do
    h = @h.map_values{|v| v.upcase}
    h.values.should == @h.values.map{|v| v.upcase}
    h.keys.should == @h.keys
    h.map_values!{ 1 }
    h.values.should == [1,1]
  end
  
  it "mkdir_p's and trees" do
    h = {}
    h.mkdir_p(["a", "b", "c"]).should == {"a"=>{"b"=>{"c"=>{}}}}
    h.mkdir_p(["a", "b", "whoa"]).should == {"a"=>{"b"=>{"c"=>{}, "whoa"=>{}}}}
    
    lambda { 
      h.tree.should == ["a", "  b", "    c", "    whoa"]
    }.should_not raise_error
  end
  
  it "to_querys" do
    # this will probably fail half the time in Ruby 1.8 because the hash order is random
    params = {"donkeys"=>"7", "stubborn"=>"true"}
    params.to_query.to_params.should == params
    params.to_query.in?(["donkeys=7&stubborn=true", "stubborn=true&donkeys=7"]).should == true
  end
  
  it "includes?s and key?s" do
    @h.key?("key1").should == true
    @h.includes?("key1").should == true
  end
  
end


describe Time do
  it "time in words" do
    Time.now.in_words.should == "just now"
    1.second.ago.in_words.should == "1 second ago"
    2.seconds.ago.in_words.should == "2 seconds ago"
    3.weeks.ago.in_words.should == "3 weeks ago"
    4.5.weeks.ago.in_words.should == "1 month ago"
    2.months.ago.in_words.should == "2 months ago"
    2.years.ago.in_words.should == "2 years ago"
    2.5.years.ago.in_words.should == "2 years ago"

    2.5.years.from_now.in_words.should == "2 years from now"
  end
end


describe Binding do
  a = 1
  b = proc { a }
  
  b.binding.keys.should == [:a, :b]
  b.binding.keys.should == b.binding.local_variables
  
  b.binding[:a].should == 1
  b.binding["a"].should == 1
  b.binding[:b].should == b
  
  b.binding[:a] = 5
  b.binding[:a].should == 5
  b.call.should == 5
end

describe Proc do

  it "joins procs" do
    a = proc { 1 } & proc { 2 }
    a.call.should == [1,2]

    a &= proc { 3 }
    a.call.should == [[1,2],3]
  end
  
  it "chains procs" do
    b = proc { 1 } | proc { |input| input + 1 }
    b.call.should == 2
    b = b.chain( proc { |input| input + 1 } )
    b.call(1).should == 3 
  end
    
end


describe BasicObject do
  
  it "is blank!" do
    BasicObject.methods(false).should == []
  end
  
end


describe "truthiness" do
  
  it "is truthy!" do
    {
      # truthy things
      true => [
        "yes", "on", "1", "Enabled", 1, 1.7, :blah, true, [1,2,3], Enumerator.new([1,2,3], :each),
        1938389127239847129803741980237498012374,
      ],
      
      # untruthy things
      false => [
        "", " ", "asdf", 0, 0.0, false, nil, [], Enumerator.new([], :each),
      ]
    }.each do |truthiness, objs|
      objs.each { |obj| obj.truthy?.should == truthiness }
    end
  end
  
end

describe "proper grammar" do

  it "responds_to?" do
    proc{}.responds_to?(:call).should == true
  end
  
  it "includes?" do
    [1,2,3,4,5].includes?(5).should == true
  end
  
  it "is_an?" do
    Object.new.is_an?(Object).should == true
  end

end


describe "metaclass" do

  it "metaclass" do
    o = Object.new
    o_metaclass = class << o; self; end
    o.metaclass.should == o_metaclass
  end

end


describe "global methods" do

  it "locals's" do
    require 'binding_of_caller'
  
    a = 5
    b = 10
    _what_ = :splunge
    
    locals.should == {:a=>5, :b=>10}
  end

end

describe "to_jsons and to_yamls" do
  data = {"a"=>"b", "yes"=>true, "hello"=>[1,2,3,4,5]}
  data.to_json.from_json.should == data  

  data = {:a=>"b", 1=>true, "hello"=>[1,2,3,4,5]}
  data.to_yaml.from_yaml.should == data  
end

