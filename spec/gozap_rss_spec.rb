require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "GozapRss" do
  it "hello" do
     GozapRss::VERSION.should ==  "0.0.5"
  end

  it "test xml" do
    rss = GozapRss::ChoutiRss.new("http://www.neihan8.com/data/rss/3.xml")
    puts rss.items[0].title
    rss.items.count.should >  1
    #rss1 =  RSS::Parser.parse("http://hi.baidu.com/cwyalpha/rss", false)
    #puts rss1.items

  end

end
