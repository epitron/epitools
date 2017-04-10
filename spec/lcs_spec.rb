require 'epitools/lcs'

describe "Longest common subsequence" do

  it "works!" do
    prefix_strings = [
     "shenanigans, gentlemen!",
      "shenanigans has been called",
      "shenanigans: a great restaurant."
    ]

    subsequence_strings = [
      "i call shenanigans on you!",
      "shenanigans is a great restaurant.",
      "you like this? shenanigans!"
    ]

    longest_common_prefix(prefix_strings).should == "shenanigans"
    longest_common_subsequence(*subsequence_strings[0..1]).should == 12
  end

end

