#encoding utf8

module GozapRss

  class Error < StandardError; end

  class GozapHttpTimeOutError < Error
    def initialize(url)
      super("http get #{url} get timeout")
    end
  end

  class GozapHttpStatusError < Error
    def initialize(url, code, msg)
      super("http get #{url} return response_code is #{code} and error is #{msg}")
    end
  end

  class GozapHttpReceiveError < Error
    def initialize(url, msg)
      super("http get #{url} error is #{msg}")
    end
  end


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

    attr_reader :items

    def initialize uri
      @http_headers_option = {"User-Agent" => "Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7"}
      @url = uri
      @items = []
      @ttl = 120
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
        @ttl =  rss.channel.ttl.to_i * 60 if (rss.channel.respond_to?(:ttl) && rss.channel.ttl.to_i > 0)
        rss.items.each do |item|
          rss_item = ChoutiRssItem.new(item)
          @items << rss_item if rss_item
        end
      rescue Exception => e
        logger_exception e
      end

    end


    #because some site feed refuse rss robot, so i set the http headers User-Agent to disguise as a browser
    def get_feed_content uri

      content = ""
      @retry = 3
      begin
        response = Typhoeus::Request.get(uri,
                                         :headers['User-Agent'] => "Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.7"\
                                                    "(KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7",
                                         :timeout => 30000,
                                         :max_redirects => 3,
                                         :follow_location => true
        )

        if response.success? || (response.code < 400 && response.code >= 301)
          content = response.body
          #isutf8 = Kconv.isutf8(content)
          #content = content.encode("UTF-8", "GB2312")    unless isutf8
        elsif response.timed_out?
          raise GozapHttpTimeOutError.new(uri)
        elsif response.code == 0
          raise GozapHttpReceiveError.new(uri,response.curl_error_message)
        else
          rails GozapHttpStatusError.new(uri, response.code, response.curl_error_message)
        end
      rescue GozapHttpTimeOutError => e
        logger_exception e
        logger.info "#{@retry} #{uri}"
        retry if  (@retry -= 1) > 0
      rescue GozapHttpReceiveError => e
        logger_exception e
        logger.info "retry #{@retry} #{uri}"
        retry if  (@retry -= 1) > 0
      rescue Exception => e
        logger_exception e
      end
      return content
    end

  end


  class ChoutiRssItem < ChoutiRssBase

    def initialize item
      @title = item.title.to_s.html_format
      @description = item.description.to_s.html_format
      @url = item.link.to_s.strip
      unless validate
        logger.error "parser item error -- title=>#{@title},  url=>#{@url}"
        return nil
      end
      self
    end

    private
    def validate
      !(@url.nil? || @title.nil? ||
          @url.empty? ||  @title.empty?)
    end

  end
end
