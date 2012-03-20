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


    attr_reader :content, :url, :description, :title, :pub_date, :ttl
    attr_accessor :http_headers_option


  end


  class ChoutiRss < ChoutiRssBase

    attr_reader :items

    def initialize uri

      @url = uri
      @items = []
      @ttl = 120
      @content = get_feed_content uri
      parse_rss
    end
    ENCODING = /\bencoding\s*=\s*["'](.*?)['"]/um

    private

    def create_from(arg)
      if arg.respond_to? :read and
          arg.respond_to? :readline and
          arg.respond_to? :nil? and
          arg.respond_to? :eof?
        puts "IO"
      elsif arg.respond_to? :to_str
        require 'stringio'
        puts "string"
      elsif arg.kind_of? Source
       puts "self"
      else
        raise "#{arg.class} is not a valid input stream.  It must walk \n"+
                  "like either a String, an IO, or a Source."
      end
    end

    def from_iso_8859_15(str)
      array_latin9 = str.unpack('C*')
      array_enc = []
      array_latin9.each do |num|
        case num
          # characters that differ compared to iso-8859-1
          when 0xA4; array_enc << 0x20AC
          when 0xA6; array_enc << 0x0160
          when 0xA8; array_enc << 0x0161
          when 0xB4; array_enc << 0x017D
          when 0xB8; array_enc << 0x017E
          when 0xBC; array_enc << 0x0152
          when 0xBD; array_enc << 0x0153
          when 0xBE; array_enc << 0x0178
          else
            array_enc << num
        end
      end
      array_enc.pack('U*')
    end


    # Convert from UTF-8
    def to_iso_8859_15(content)
      array_utf8 = content.unpack('U*')
      array_enc = []
      array_utf8.each do |num|
        case num
          # shortcut first bunch basic characters
          when 0..0xA3; array_enc << num
          # characters removed compared to iso-8859-1
          when 0xA4; array_enc << '&#164;'
          when 0xA6; array_enc << '&#166;'
          when 0xA8; array_enc << '&#168;'
          when 0xB4; array_enc << '&#180;'
          when 0xB8; array_enc << '&#184;'
          when 0xBC; array_enc << '&#188;'
          when 0xBD; array_enc << '&#189;'
          when 0xBE; array_enc << '&#190;'
          # characters added compared to iso-8859-1
          when 0x20AC; array_enc << 0xA4 # 0xe2 0x82 0xac
          when 0x0160; array_enc << 0xA6 # 0xc5 0xa0
          when 0x0161; array_enc << 0xA8 # 0xc5 0xa1
          when 0x017D; array_enc << 0xB4 # 0xc5 0xbd
          when 0x017E; array_enc << 0xB8 # 0xc5 0xbe
          when 0x0152; array_enc << 0xBC # 0xc5 0x92
          when 0x0153; array_enc << 0xBD # 0xc5 0x93
          when 0x0178; array_enc << 0xBE # 0xc5 0xb8
          else
            # all remaining basic characters can be used directly
            if num <= 0xFF
              array_enc << num
            else
              # Numeric entity (&#nnnn;); shard by  Stefan Scholl
              array_enc.concat "&\##{num};".unpack('C*')
            end
        end
      end
      array_enc.pack('C*')
    end

    def transe_code
      @content = from_iso_8859_15(@content)
      encoding = ENCODING.match(@content)
      @content = to_iso_8859_15(@content)
      if encoding && encoding[1].upcase[0..1] == "GB"
        @content = @content.force_encoding("GBK").encode("UTF-8")
        @content = @content.gsub(/\bencoding\s*=\s*["'](.*?)['"]/um, "encoding='UTF-8'")
      end
    end

    def parse_rss
      return if @content.nil? or @content.empty?
      begin
        transe_code
        rss = RSS::Parser.parse(@content, false)
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


    def get_feed_content uri
      retry_times = 3
      content = ""
      begin
        content = ""
        open(uri, "User-Agent" => "Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.7 (KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7",
             :read_timeout => 60, :redirect => true) do |f|
            content = f.read
            #p f.charset
            #p f.content_encoding
            #p content.encoding.to_s
        end
        #content = content.force_encoding("UTF-8")

      rescue  Exception=>e
        logger_exception  e
        logger.info "retry #{retry_times} #{uri}"

        retry if (retry_times -= 1) > 0
      end
      return content
    end


    #because some site feed refuse rss robot, so i set the http headers User-Agent to disguise as a browser
    #def get_feed_content(uri)
    #
    #  content = ""
    #  @retry = 3
    #  begin
    #    response = Typhoeus::Request.get(uri,
    #                                     :headers['User-Agent'] => "Mozilla/5.0 (X11; Linux i686) AppleWebKit/535.7"\
    #                                                "(KHTML, like Gecko) Chrome/16.0.912.75 Safari/535.7",
    #                                     :timeout => 30000,
    #                                     :max_redirects => 3,
    #                                     :follow_location => true
    #    )
    #
    #    if response.success? || (response.code < 400 && response.code >= 301)
    #      content = response.body
    #
    #    elsif response.timed_out?
    #      raise GozapHttpTimeOutError.new(uri)
    #    elsif response.code == 0
    #      raise GozapHttpReceiveError.new(uri,response.curl_error_message)
    #    else
    #      rails GozapHttpStatusError.new(uri, response.code, response.curl_error_message)
    #    end
    #  rescue GozapHttpTimeOutError => e
    #    logger_exception e
    #    logger.info "#{@retry} #{uri}"
    #    retry if  (@retry -= 1) > 0
    #  rescue GozapHttpReceiveError => e
    #    logger_exception e
    #    logger.info "retry #{@retry} #{uri}"
    #    retry if  (@retry -= 1) > 0
    #  rescue Exception => e
    #    logger_exception e
    #  end
    #  return content
    #end

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
