require 'epitools'

describe Numeric do
  
  it "to_wordses" do
    {
      10 => "ten",
      3_123 => "three thousand, one-hundred and twenty-three",
      123_124 => "one-hundred and twenty-three thousand, one-hundred and twenty-four",
      
      8_128_937_981_273_987_129_837_174_612_897_638_613 => "eight undecillion, one-hundred and twenty-eight decillion, nine-hundred and thirty-seven nonillion, nine-hundred and eighty-one octillion, two-hundred and seventy-three septillion, nine-hundred and eighty-seven sextillion, one-hundred and twenty-nine quintillion, eight-hundred and thirty-seven quadrillion, one-hundred and seventy-four trillion, six-hundred and twelve billion, eight-hundred and ninety-seven million, six-hundred and thirty-eight thousand, six-hundred and thirteen",
      
      3_486_597_230_495_871_304_981_320_498_123_498_263_984_739_841_834_091_823_094_812_039_481_231_623_987_461_293_874_698_123_649_817_236 => "three duotrigintillion, four-hundred and eighty-six untrigintillion, five-hundred and ninety-seven trigintillion, two-hundred and thirty novemvigintillion, four-hundred and ninety-five octovigintillion, eight-hundred and seventy-one septenvigintillion, three-hundred and four sexvigintillion, nine-hundred and eighty-one quinvigintillion, three-hundred and twenty quattuorvigintillion, four-hundred and ninety-eight trevigintillion, one-hundred and twenty-three duovigintillion, four-hundred and ninety-eight unvigintillion, two-hundred and sixty-three vigintillion, nine-hundred and eighty-four novemdecillion, seven-hundred and thirty-nine octodecillion, eight-hundred and fourty-one septendecillion, eight-hundred and thirty-four sexdecillion, ninety-one quindecillion, eight-hundred and twenty-three quattuordecillion, ninety-four tredecillion, eight-hundred and twelve duodecillion, thirty-nine undecillion, four-hundred and eighty-one decillion, two-hundred and thirty-one nonillion, six-hundred and twenty-three octillion, nine-hundred and eighty-seven septillion, four-hundred and sixty-one sextillion, two-hundred and ninety-three quintillion, eight-hundred and seventy-four quadrillion, six-hundred and ninety-eight trillion, one-hundred and twenty-three billion, six-hundred and fourty-nine million, eight-hundred and seventeen thousand, two-hundred and thirty-six",
      
      1763241823498172490817349807213409238409123409128340981234781236487126348791263847961238794612839468917236489712364987162398746129834698172364987123 => "more than a googol! (148 digits)"      
    }.each do |num, result|
      num.to_words.should == result
    end
    
    lambda{ 1.523.million.billion.to_words }.should_not raise_error
  end

  it "has .thousand, .million, etc." do
    10.thousand.should == 10_000
    20.billion.should == 20_000_000_000
    1.9.million.should == 1_900_000
    37.2872.duotrigintillion.should == 37287200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    lambda { 10.googol }.should raise_error
  end
  
  it "handles 1.thousand.to_words properly" do
    1.thousand.to_words.should == "one thousand"
  end

  it "handles 1.quadrillion.to_words properly" do
    1.quadrillion.to_words.should == "one quadrillion"
  end
  
end
