#encoding utf8

module GozapRss


  class ChoutiRssBase
    def self.logger
      @logger || GozapRss.logger || Logger.new(STDOUT)
    end

    def self.logger= logger
      @logger = logger if logger
    end

    def self.logger_exception e
      logger.error e
      logger.error e.backtrace
    end

    def logger
      self.class.logger
    end

    def log_failed(response)
      msg = "#{response.code} URL: #{response.request.url}  PARAMS: #{response.request.params.to_s} in #{response.time}s FAILED :  #{response.curl_error_message}
      BODY: #{response.body}"
      logger.error(msg)
    end

    def logger_exception e
      self.class.logger_exception e
    end


    attr_reader :url, :description, :title, :pub_date, :ttl
    attr_accessor :http_headers_option


  end


  class ChoutiRss < ChoutiRssBase

    attr_reader :rss_items

    def initialize uri
      @http_headers_option = {"User-Agent" => "Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7"}
      @url = uri
      @rss_items = []
      content = get_feed_content uri
      parse_rss(content)
    end


    private

    def parse_rss content
      return if content.nil? or content.empty?
      begin
        rss = RSS::Parser.parse(content, false)
        @title = rss.channel.title.to_s.html_format
        @description = rss.channel.description.to_s.html_format
        @pub_date = rss.channel.pubDate
        @ttl = rss.channel.ttl.to_i == 0 ? 10 * 60 : rss.channel.ttl.to_i * 60
        @rss_items = []
        rss.items.each do |item|
          rss_item = ChoutiRssItem.new(item)
          @rss_items << rss_item if rss_item
        end
        @rss_items.sort! { |a, b| b.pub_date <=>a.pub_date }
      rescue Exception => e
        logger_exception e
      end

    end


    #because some site feed refuse rss robot, so i set the http headers User-Agent to disguise as a browser
    def get_feed_content uri

      content = ""
      begin
        response = Typhoeus::Request.get(uri,
                                         :headers['User-Agent'] => "Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.7"\
                                                    "(KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7",
                                         :timeout => 120000,
                                         :max_redirects => 3,
                                         :follow_location => true
        )

        if response.success? || (response.code < 400 && response.code >= 301)
          content = response.body
          isutf8 = Kconv.isutf8(content)
          content = Iconv.iconv("UTF-8//IGNORE", "GB2312//IGNORE", content)[0] unless isutf8
        elsif response.timed_out?
          log_failed response
        elsif response.code == 0
          log_failed(response)
        else
          log_failed(response)
        end
      rescue Exception => e
        logger_exception e
      end
      return content
    end

  end


  class ChoutiRssItem < ChoutiRssBase
    attr_reader :url_md5

    def initialize item
      @title = item.title.to_s.html_format
      @pub_date = item.pubDate || item.lastBuildDate
      @description = item.description.to_s.html_format
      @url = item.link.to_s.strip
      @url_md5 = Digest::MD5.hexdigest(@url)
      unless validate
        logger.error "parser item error -- title=>#{@title}, pub_date=>#{@pub_date} description=>#{@description}, url=>#{@url}"
        return nil
      end
      self
    end

    private
    def validate
      !(@url.nil? || @description.nil? || @title.nil? ||
          @url.empty? || @description.empty? || @title.empty?)
    end

  end
end
