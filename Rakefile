require 'rubygems'
require 'rubygems/builder'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|
  s.name = 'simple-json'
  s.version = '1.0.0'
  s.author = 'Louis-Philippe Perron'
  s.email = 'lp@spiralix.org'
  s.homepage = 'http://simple-json.rubyforge.org/'
  s.rubyforge_project = 'SimpleJSON'
	s.summary = "Rack app, JSON frontend to Amazon's SimpleDB"
  s.description = "SimpleJSON is a Rack based JSON frontend server to Amazon's SimpleDB, designed to be used as a simple backend data servers for client side web apps."
  s.files = FileList["{lib,test}/**/*"].exclude("config.ru").to_a
  s.test_file = "test/tc_simple_json.rb"
	s.add_dependency("rack", '>= 0.0.0')
  s.add_dependency("json", '>= 0.0.0')
	s.add_dependency("aws-sdb", '>= 0.0.0')
	s.requirements << 'an Amazon Web Service account to access SimpleDB'
end
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end
