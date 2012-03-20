require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'csv'
describe "GozapRss" do
  it "hello" do
     GozapRss::VERSION.should ==  "0.0.6"
  end

  it "test xml" do
    index = 0
    CSV.foreach("./chouti_rss.csv") do |row|
      rss = GozapRss::ChoutiRss.new row[1]
      if rss.items.nil?
        puts row[1] + " nil"
      end
      index += 1
      puts  "#{index}: #{row[1]} =>  #{rss.items.count}" if rss.items

    end

    #rss = GozapRss::ChoutiRss.new("http://hi.baidu.com/cwyalpha/rss")
    ##
    #puts rss.items[1].title
    #rss.items.count.should >  1
    ##rss = RSS::Parser.parse("")
    ##rss.items.count.should >  1

  end

end
