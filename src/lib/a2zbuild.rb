require_relative 'install.rb'
require_relative 'transform.rb'
require_relative 'build.rb'
require_relative 'dependency.rb'

# installation
installers = [
  'ruby', 'devkit', 'gems'
]

installers.each { |method|
  exit if !send("check_#{method}")
}

require 'rubygems'
require 'nokogiri'
require 'azure'

# includes for rake build
include FileTest
require 'albacore'
require 'semver'
