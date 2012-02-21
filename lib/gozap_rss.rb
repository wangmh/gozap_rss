require 'rubygems'
require 'logger'
require 'json'
require "mysql2"
require 'kconv'
require 'iconv'
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'


__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless $LOAD_PATH.include?(__DIR__) ||
    $LOAD_PATH.include?(File.expand_path(__DIR__))

require "gozap_rss/version.rb"

module GozapRss
  class << self
    def data_dir(path)
      if datadir = Gem.datadir("gozap_rss")
        File.join(datadir, path)
      else
        ""
      end

    end

    def logger
      @@logger ||= Logger.new(STDOUT)
    end

    def logger=(logger)
      @@logger = logger
    end

  end
end




logger = Logger.new(STDOUT)


#source = "http://feed.36kr.com/c/33346/f/566026/index.rss" # url or local file
content = "" # raw content of rss feed will be loaded here
#
client = Mysql2::Client.new(:socket=>"/var/run/mysqld/mysqld.sock", :username=>"root");
#

#
ids = [232]
failed_ids = [];

# errno

# timeout  -1;
# notwellformat -2;
#


str = ""
File.open("/home/saint/rss2.php").each do |line|
  str << line
end


ids.each do |id|
  result = client.query("select id, name,url from chouti.feed where id = #{id} ");
  result.each do |row|
    begin
      #  logger.info row["id"].to_s + "---->" + row["name"]
      open("http://rss.sina.com.cn/news/society/focus15.xml", "User-Agent"=>"Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7") do |s|
        content = s.read
      end
      isutf8 = Kconv.isutf8(content)
      content = Iconv.iconv("UTF-8//IGNORE", "GB2312//IGNORE", content)[0] unless isutf8

      puts isutf8.to_s + "-----------"
      #encoding = str.scan(
      #  /^<\?xml [^>]*encoding="([^\"]*)"[^>]*\?>/
      #).flatten.first
      content.gsub!(/^<\?xml [^>]*encoding="([^\"]*)"[^>]*\?>/, "")

      encoding = encoding || "utf8";
      #
      puts encoding
      # RSS::Parser.default_parser= "XMLParserParser" ;
      rss = RSS::Parser.parse(content, false)

      logger.info rss.channel.title
      logger.info rss.channel.link
      logger.info rss.channel.description
      logger.info rss.items.size
      logger.info rss.channel.pubDate
      logger.info rss.channel.lastBuildDate
      logger.info rss.items[0].title
      logger.info rss.items[0].date


    rescue Exception => e
      logger.error e
      logger.error e.backtrace
      failed_ids << row["id"]
    end
  end
end

puts failed_ids.join(",")
#
#failed_ids.each do |id|
#  puts id
#end






