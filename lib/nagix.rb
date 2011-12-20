# Add nagix library path if necessary
nagix_lib = File.dirname(__FILE__)
$LOAD_PATH.unshift(nagix_lib) unless $LOAD_PATH.include?(nagix_lib)

require 'nagix/mk_livestatus'
require 'nagix/nagios_object'
require 'nagix/nagios_external_command'
require 'nagix/version'
require 'nagix/nql'

module Nagix
end
