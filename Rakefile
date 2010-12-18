require 'rubygems'

#require 'bundler'
#begin
#  Bundler.setup(:default, :development)
#rescue Bundler::BundlerError => e
#  $stderr.puts e.message
#  $stderr.puts "Run `bundle install` to install missing gems"
#  exit e.status_code
#end

require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "epitools"
  gem.summary = %Q{NOT UTILS... METILS!}
  gem.description = %Q{Miscellaneous utility libraries to make my life easier.}
  gem.email = "chris@ill-logic.com"
  gem.homepage = "http://github.com/epitron/epitools"
  gem.authors = ["epitron"]
  gem.license = "WTFPL"

  # Include your dependencies below. Runtime dependencies are required when using your gem,
  # and development dependencies are only needed for development (ie running rake tasks, tests, etc)
  #  gem.add_runtime_dependency 'jabber4r', '> 0.1'
  #  gem.add_development_dependency 'rspec', '> 1.2.3'
  gem.add_development_dependency "rspec", "~> 2.2.0"
  gem.add_development_dependency "mechanize", "~> 1.0.0"
  gem.add_development_dependency "sqlite3-ruby"
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

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "epitools #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
