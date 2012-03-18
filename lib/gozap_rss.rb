require 'rubygems'
require 'logger'
require 'json'
require "mysql2"
require 'kconv'
require 'iconv'
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require "digest/md5"
require "sanitize"
require "typhoeus"




__DIR__ = File.dirname(__FILE__)

$LOAD_PATH.unshift __DIR__ unless $LOAD_PATH.include?(__DIR__) ||
    $LOAD_PATH.include?(File.expand_path(__DIR__))

require "gozap_rss/gozap_ext"
require "gozap_rss/version.rb"
require "gozap_rss/chouti_rss"


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








