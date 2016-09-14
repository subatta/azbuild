require_relative 'colorize.rb'
require_relative 'install.rb'
require_relative 'build.rb'
require_relative 'dependency.rb'
require_relative 'versioning.rb'
require_relative 'package.rb'

# installation
installers = [
  'ruby', 'gems'
]

installers.each { |method|
  exit if !send("check_#{method}")
}

#require 'rubygems'
require 'nokogiri'

# includes for rake build
include FileTest
require 'albacore'
require 'semver'
