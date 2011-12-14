# -*- encoding: utf-8 -*-
require File.expand_path("../lib/nagix/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "nagix"
  s.version     = Nagix::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = "Gerardo López-Fernádez"
  s.email       = 'gerir@ning.com'
  s.homepage    = ''
  s.summary     = "Nagios Toolkit"
  s.description = "Nagios Toolkit, incluing a command interface, RESTish and HTTP-based NSCA interfaces"

  s.required_rubygems_version = ">= 1.3.5"

  s.add_dependency('sinatra', '>= 1.2.3')
  s.add_dependency('sinatra-respond_to', '>= 0.7.0' )
  s.add_dependency('haml', '>= 3.0.25')
  s.add_dependency('json', '>= 1.5.1')

  s.files        = Dir.glob("{bin,lib,public,views}/**/*")
  s.executables  = [ 'ngsh', 'nagix']
  s.require_path = 'lib'
end
