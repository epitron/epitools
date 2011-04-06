require 'epitools/browser'

class Mechanize::Page
  def url
    uri.to_s
  end
end



describe Browser do

  before :all do
    @browser = Browser.new
  end

  after :all do
    @browser.cache.delete!
  end

  it "googles" do
    page = @browser.get("http://google.com")
    page.body["Feeling Lucky"].should_not be_empty
  end
  
  it "googles (cached)" do
    lambda{ @browser.get("http://google.com").body }.should_not raise_error
  end
  
  it "delegates" do
    lambda{ @browser.head("http://google.com").body }.should_not raise_error
    @browser.respond_to?(:post).should == true
    @browser.respond_to?(:put).should == true
  end

end



describe Browser::Cache do

  before :all do
    @agent = Mechanize.new
    Browser::Cache.new(@agent).delete!
    @cache = Browser::Cache.new(@agent)
  end

  def new_page(body, url)
    Mechanize::Page.new(
      URI.parse(url),
      {'content-type'=>'text/html'},
      body,
      nil,
      @agent
    )
  end

  after :all do
    @cache.delete!
  end

  it "writes and reads" do
    body = "Blah blah blah."
    url  = "http://example.com/url.html"

    page = new_page(body, url)

    page.body.should == body
    page.url.should == url

    @cache.put page, url
    @cache.urls.size.should == 1
    @cache.includes?(url).should == true

    result = @cache.get url

    body.should == page.body
    body.should == result.body
    url.should == page.url
    url.should == result.url
  end

end