require 'epitools/semantic_version'

describe SemanticVersion do

  it "works" do
    [
      ["3.1.3pre1", "3.1.3-1", -1],
      ["1.15.10+54+g1ed124ace-1", "1.15.10-1", 1],
      ["0.30+2+gc0620e4-1", "0.30pre1", 1],
      ["1:0.27.2-1", "1:0.27.2-2", -1],
      ["0+337-2", "1", -1],
      # ["1.0", "1", 0], # <- fix this
      ["1.0", "1.0", 0],
      ["2:1.11-1", "1.9.4-1", 1],
    ].each do |a,b,target|
      result = SemanticVersion.compare(a,b)

      result.should == target

      case target
      when -1
        SemanticVersion.new(a).should be < SemanticVersion.new(b)
      when 1
        SemanticVersion.new(a).should be > SemanticVersion.new(b)
      when 0
        SemanticVersion.new(a).should == SemanticVersion.new(b)
      end
    end
  end

end

