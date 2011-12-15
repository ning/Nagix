lib = File.expand_path(File.dirname(__FILE__) + '/lib')
$LOAD_PATH.unshift(lib) if File.directory?(lib) && !$LOAD_PATH.include?(lib)

require 'rubygems'
require 'nagix'
require 'nagix/http'

run Nagix::App
