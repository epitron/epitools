require 'epitools/browser'

describe Browser do

  before :all do
    @browser = Browser.new
  end
  
  it "googles" do
    page = @browser.get("http://google.com")
    page.body["Feeling Lucky"].should_not be_empty
  end

end