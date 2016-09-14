require 'net/http'

$ruby_version_map = {
  '2.3.1-p112' => {
    :gems => {
      'nokogiri' => '1.6.8',
      'albacore' => '2.6.1',
      'semver2' => '3.4.2',
      'nuget' => '3.2.0'
    }
  }
}

$selected_version = {}

# Ruby version check
def check_ruby
  puts "Checking ruby version...".bg_green.white if (ENV['debug'])

  # check if expected ruby version exists. If not download and install ruby
  rubyVersion = "#{RUBY_VERSION}"
  localVersion = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
  expectedVersions = $ruby_version_map.keys
  if (!rubyVersion.nil? && !expectedVersions.include?(localVersion))
    puts "Uninstall incompatible version of ruby: #{localVersion} and " \
    	"install any one of these Ruby versions: #{expectedVersions}. " \
    	"Then Restart rake. Goto http://rubyinstaller.org/downloads/".red
    return false
  else
    puts "#{localVersion} is the expected version.".green if (ENV['debug'])
  end

  $selected_version = $ruby_version_map[localVersion]
  if ($selected_version != nil)
    puts "Ruby version found: #{localVersion}".green if (ENV['debug'])
    puts 'Ruby ok'.green if (ENV['debug'])
  end
  return true
end

# check and install required gems
def check_gems
  puts 'Checking required gems...'.bg_green.white if (ENV['debug'])
  $selected_version[:gems].each {|key, value|
    if !gem_exists(key, value)
      begin
        puts "Installing missing gem: #{key}".bg_green.white
        cmd = "gem install #{key} -v #{value}"
        cmdoutput = `#{cmd}`
        puts cmdoutput.bg_green.white
      rescue
        puts 'gem install failed'.red
        puts $!
        return false    # don't continue if even one gem install fails
      end
    else
      puts "Gem #{key}, #{value} exists".green if (ENV['debug'])
    end
  }
  # all gems installed
  return true
end

# Checks if a gem of a version exists
def gem_exists(name, version)
  begin
    gem name, "=#{version}"
  rescue Gem::LoadError
    puts "failed to load gem #{name} -v #{version}".red
    Gem.clear_paths
    return false
  end
  return true
end
