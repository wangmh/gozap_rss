#encoding utf8

module GozapRss

  class ChoutiRss
    def self.logger
      @logger || GozapRss.logger
    end

    def self.logger= logger
      @logger  = logger if logger
    end

    def logger
      ChoutiRss.logger
    end

    def initialize(str)

    end


  end
end
