require 'epitools/highlight'

describe String do

  it "highlights" do
    color = :light_yellow
    highlighted = "xxx#{"match".send(color)}zzz"

    "xxxmatchzzz".highlight(/match/, color).should   == highlighted
    "xxxmatchzzz".highlight("match", color).should   == highlighted
    "xxxmatchzzz".highlight(/m.+h/, color).should    == highlighted
    "xxxmatchzzz".highlight(/MATCH/i, color).should  == highlighted
  end
  
end