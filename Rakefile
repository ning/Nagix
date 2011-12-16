require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "nagix"
    gem.summary = %Q{Nagios Toolkit, incluing a command interface, RESTish and HTTP-based NSCA interfaces}
    gem.description = %Q{Nagios Toolkit, incluing a command interface, RESTish and HTTP-based NSCA interfaces}
    gem.email = "gerir@ning.com"
    gem.homepage = "https://github.com/ning/Nagix"
    gem.authors = ["Gerardo López-Fernádez"]
    gem.license = 'ASL2'
    gem.required_ruby_version = '>= 1.8.7'
    gem.files = FileList['lib/**/*.rb', 'bin/*', 'config.ru', 'public/**/*', 'views/**/*', '[A-Z]*'].to_a
    gem.add_development_dependency 'yard', '~> 0.6.1'
    gem.add_dependency 'sinatra', '>= 1.2.3'
    gem.add_dependency 'sinatra-respond_to', '>= 0.7.0'
    gem.add_dependency 'haml', '>= 3.0.25'
    gem.add_dependency 'json', '>= 1.5.1'
    gem.add_dependency 'log4r', '>= 1.1.9'
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

task :default => :build

begin
  require 'yard'

  YARD::Rake::YardocTask.new
rescue LoadError
  puts "Yard (or a dependency) not available. Install it with: gem install yard"
end

