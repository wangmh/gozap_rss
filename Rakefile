#encoding: utf-8

require 'rubygems'
require 'bundler'
$:.unshift File.join(File.dirname(__FILE__), 'lib')
require 'gozap_rss/version'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "gozap_rss"
  gem.homepage = "http://github.com/wangmh/gozap_rss"
  gem.license = "MIT"
  gem.summary = %Q{gozap公司用来抓取rss的服务}
  gem.description = %Q{抓取RSS服务的简单应用}
  gem.email = "wangmh.bit@gmail.com"
  gem.authors = ["王明华"]
  gem.version = GozapRss::VERSION
  gem.files = FileList['lib/**/*.rb', '[A-Z]*', 'spec/**/*'].to_a

  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version =   GozapRss::VERSION
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "gozap_rss #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
