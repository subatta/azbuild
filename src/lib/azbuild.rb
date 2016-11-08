require_relative 'string_extensions.rb'
require_relative 'build.rb'
require_relative 'versioning.rb'
require_relative 'package.rb'
require_relative 'semver_extensions'

require 'nokogiri'

# includes for rake build
include FileTest
require 'albacore'
require 'semver'
require 'json'