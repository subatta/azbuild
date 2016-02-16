require 'net/http'

$ruby_version_map = {
  '1.9.3-p551' => {
    :devkit => 'DevKit-tdm-32-4.5.2-20111229-1559-sfx.exe',
    :gems => {
      'albacore' => '0.3.5',
      'semver2' => '3.3.3',
      'nokogiri' => '1.6.4.1',
      'zip' => '2.0.2',
      'azure' => '0.6.4'
    },
  },
  '2.0.0-p481' => {
    :devkit => 'DevKit-mingw64-32-4.7.2-20130224-1151-sfx.exe',
    :gems => {
      'albacore' => '0.3.6',
      'semver2' => '3.3.3',
      'nokogiri' => '1.6.4.1',
      'azure' => '0.6.4'
    }
  },
  '2.2.3-p173' => {
    :devkit => 'DevKit-mingw64-32-4.7.2-20130224-1151-sfx.exe',
    :gems => {
      'nokogiri' => '1.6.7.rc3',
      'albacore' => '2.5.5',
      'semver2' => '3.4.2',
      'azure' => '0.7.1',
      'nuget' => '2.8.60717.93'
    }
  }
}

$selected_version = {}

def download_file(sourcePath, filePath, localFileLocation)
  Net::HTTP.start(sourcePath) do |http|
    resp = http.get(filePath)
    f = open(localFileLocation, 'wb')
    begin
      requestPath = "http://#{sourcePath}#{filePath}"
      puts "Downloading #{requestPath}..."
      http.request_get(requestPath) do |resp|
        resp.read_body do |segment|
          f.write(segment)
        end
      end
    rescue
      puts $!
      return false
    ensure
      f.close()
    end
  end
  return true
end

def install_file(cmd, versionedExeFile)
  begin
    installerOutput = `#{cmd}`
    puts installerOutput
  rescue
    puts $!
    return false
  ensure
    puts 'Cleaning up...'
    cmd = "#{versionedExeFile}"
    installerOutput = `del #{cmd}`
    puts installerOutput
  end
  return true
end

def gem_exists(name, version)
  begin
    gem name, "=#{version}"
  rescue Gem::LoadError
    puts "failed to load gem #{name} -v #{version}"
    Gem.clear_paths
    return false
  end
  return true
end

# Ruby version check
def check_ruby
  puts 'Checking ruby version...'
  # check if expected ruby version exists. If not download and install ruby
  rubyVersion = "#{RUBY_VERSION}"
  localVersion = "#{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}"
  expectedVersions = $ruby_version_map.keys
  if (!rubyVersion.nil? && !expectedVersions.include?(localVersion))
    puts "Uninstall incompatible version of ruby: #{localVersion} and install any one of these Ruby versions: #{expectedVersions}. Then Restart rake. Goto http://rubyinstaller.org/downloads/"
    return false
  end

  $selected_version = $ruby_version_map[localVersion]
  if ($selected_version != nil)
    puts "Ruby version found: #{localVersion}"
    puts 'Ruby ok'
  end
  return true
end

### devkit version check
def check_devkit
  # check if devkit exists
  puts 'Checking devkit version...'
  rubyPath = `where.exe ruby.exe`
  rubyPath['bin\ruby.exe'] = 'devkit'
  rubyPath = rubyPath.sub("\n", '')    #doublequotes required for Line break, gotcha
  if (!File.directory?(rubyPath))
    puts 'devkit not found'
    # if not download, install and setup devkit
    puts 'Downloading devkit...'

    sourcePath = 'cdn.rubyinstaller.org'
    versionedExeFile = $selected_version[:devkit]
    filePath = "/archives/devkits/#{versionedExeFile}?direct"
    return false if !download_file(sourcePath, filePath, versionedExeFile)

    puts 'Devkit installation in progress...'
    cmd = "#{versionedExeFile} -y -o\"#{rubyPath}\""    #no space after -o, gotcha
    puts cmd
    return false if !install_file(cmd, versionedExeFile)

    puts 'Setting up devkit...'
    Dir.chdir "#{rubyPath}"
    cmd = 'ruby dk.rb init'
    cmdoutput = `#{cmd}`
    puts cmdoutput
    if !cmdoutput.to_s.include?('Initialization complete!')
      puts 'Error: could not initialize devkit.'
      return false
    end

    cmd = 'ruby dk.rb review'
    cmdoutput = `#{cmd}`
    puts cmdoutput
    if !cmdoutput.to_s.include?('DevKit functionality will be injected')
      puts 'Error: devkit review failed'
      return false
    end

    cmd = 'ruby dk.rb install'
    cmdoutput = `#{cmd}`
    puts cmdoutput
    puts 'Restart console since environment variables are now updated'

    return false
  end

  puts 'devkit ok'
  return true
end

# check and install required gems
def check_gems
  puts 'Checking required gems...'
  $selected_version[:gems].each {|key, value|
    if !gem_exists(key, value)
      begin
        puts "Installing missing gem: #{key}"
        cmd = "gem install #{key} -v #{value}"
        cmdoutput = `#{cmd}`
        puts cmdoutput
      rescue
        puts 'gem install failed'
        puts $!
        return false    # don't continue if even one gem install fails
      end
    else
      puts "Gem #{key}, #{value} exists"
    end
  }
  # all gems installed
  return true
end
