$version_map = {}

def copy_output_files(fromDir, filePattern, outDir)
  FileUtils.mkdir_p outDir unless exists?(outDir)
  Dir.glob(File.join(fromDir, filePattern)){|file|
    copy(file, outDir) if File.file?(file)
  }
end

def project_outputs(props)
  props[:projects].map{ |p| "src/#{p}/bin/#{BUILD_CONFIG}/#{p}.dll" }.
    concat( props[:projects].map{ |p| "src/#{p}/bin/#{BUILD_CONFIG}/#{p}.exe" } ).
    find_all{ |path| exists?(path) }
end

def get_commit_hash_and_date
  begin
    commit = `git log -1 --pretty=format:%H`
    git_date = `git log -1 --date=iso --pretty=format:%ad`
    commit_date = DateTime.parse( git_date ).strftime("%Y-%m-%d %H%M%S")
  rescue
    commit = "git unavailable"
  end

  [commit, commit_date]
end

def add_files stage, what_dlls, nuspec, folder='lib'
  [['net35', 'net-3.5'], ['net40', 'net-4.0'], ['net45', 'net-4.5']].each{|fw|
    takeFrom = File.join(stage, fw[1], what_dlls)
    Dir.glob(takeFrom).each do |f|
      nuspec.file(f.gsub("/", "\\"), "#{folder}\\#{fw[0]}")
    end
  }
end

def commit_data
  begin
    commit = `git rev-parse --short HEAD`.chomp()[0,6]
    git_date = `git log -1 --date=iso --pretty=format:%ad`
    commit_date = DateTime.parse( git_date ).strftime("%Y-%m-%d %H%M%S")
  rescue Exception => e
    puts e.inspect
    commit = (ENV['BUILD_VCS_NUMBER'] || "000000")[0,6]
    commit_date = Time.new.strftime("%Y-%m-%d %H%M%S")
  end
  [commit, commit_date]
end

def waitfor(&block)
  checks = 0

  until block.call || checks >10
    sleep 0.5
    checks += 1
  end

  raise 'Waitfor timeout expired. Make sure that you aren\'t running something from the build output folders, or that you have browsed to it through Explorer.' if checks > 10
end

def cleantask(props)

  if props.has_key?(:output) && File.directory?(props[:output])
    FileUtils.rm_rf props[:output]
    waitfor { !exists?(props[:output]) }
  end

  if props.has_key?(:artifacts) && File.directory?(props[:artifacts])
    FileUtils.rm_rf props[:artifacts]
    waitfor { !exists?(props[:artifacts]) }
  end

  if props.has_key?(:output)
    Dir.mkdir props[:output]
  end
  if props.has_key?(:artifacts)
    Dir.mkdir props[:artifacts]
  end
end

def versioning
  ver = SemVer.find
  revision = (ENV['BUILD_NUMBER'] || ver.patch).to_i
  var = SemVer.new(ver.major, ver.minor, revision, ver.special)

  commitData = commit_data()

  # extensible number w/ git hash
  ENV['BUILD_VERSION'] = $version_map[:build_version] = ver.format('%M.%m.%p%s') + ".#{commitData[0]}"

  # nuget (not full semver 2.0.0-rc.1 support) see http://nuget.codeplex.com/workitem/1796
  ENV['NUGET_VERSION'] = $version_map[:nuget_version] = ver.format('%M.%m.%p%s')

  ENV['PLATFORM_VERSION'] = $version_map[:platform_version] = Time.new.strftime('%y.%-m.%-d') + ".#{(ENV['BUILD_NUMBER'] || '0')}"

  ENV['PLATFORM_BUILD_VERSION'] = $version_map[:platform_build_version] = Time.new.strftime('%y.%-m.%-d') + ".#{commitData[0]}"

  # purely M.m.p format
  ENV['FORMAL_VERSION'] = $version_map[:formal_version] = "#{ SemVer.new(ver.major, ver.minor, revision).format '%M.%m.%p'}"
  puts "##teamcity[buildNumber '#{$version_map[:platform_version]}']" # tell teamcity our decision
end

def set_framework_version(asm)
  set_version asm, $version_map[:formal_version], $version_map[:formal_version], $version_map[:build_version], 'Framework'
end

def set_solution_version(asm)
  set_version asm, $version_map[:platform_version], $version_map[:platform_version], $version_map[:platform_build_version], 'Solution'
end

def set_version asm, version, file_version, assembly_version, output_file
  # Assembly file config
  asm.product_name = PRODUCT
  asm.description = PRODUCT_DESCRIPTION
  asm.version = version
  asm.file_version = file_version
  asm.custom_attributes :AssemblyInformationalVersion => assembly_version,
    :ComVisibleAttribute => false,
    :CLSCompliantAttribute => true
  asm.copyright = COPYRIGHT
  asm.output_file = "src/#{output_file}Version.cs"
  asm.namespaces 'System', 'System.Reflection', 'System.Runtime.InteropServices'
end

# checks nuget dependency
def check_package_version_dependency package_uri, package, version='IsLatestVersion'
  # retrieve package version info
  response = Net::HTTP.get_response(URI.parse(package_uri.sub('pkg', package))) # get_response takes a URI object
  package_info = response.body
  xml = Nokogiri::XML(package_info)
  xml.xpath("//m:properties/d:#{version}").each { |e|
    if e.text.to_s == 'true'
      version = e.parent.xpath('d:Version').text
    end
  }

  # grab all packages.config files
  config_files = Dir.glob('**/packages.config')

  # for each file match version. Return false is check fails
  config_files.each{ |file|
    doc = Nokogiri::XML(File.read(file))
    node = doc.at_xpath("//*[@id=\"#{package}\"]")
    if (!node.nil?)
      config_version = node.attr('version')
      puts "Package: #{package} Latest Version: #{version} File: #{file} File package version: #{config_version}"
      return false unless config_version.to_s == version
    end
  }

  return true
end

def copy_runtime_artifacts package

  # grab all packages.config files
  config_files = Dir.glob('**/packages.config')
  config_version = ''

  # find package version
  config_files.each{ |file|
    doc = Nokogiri::XML(File.read(file))
    node = doc.at_xpath("//*[@id=\"#{package}\"]")
    if (!node.nil?)
      config_version = node.attr('version').to_s
      break
    end
  }
  puts config_version

  # copy artifacts
  source = "#{ENV['RuntimePath']}/#{config_version}"
  dest = File.join(File.expand_path('.'), 'RuntimeService')
  puts source
  puts dest
  copy_output_files source, "*.*", dest
end

def run_vsconsolse_tests settings, assemblies = nil

  raise 'Settings file name is required' if settings.nil?

  if assemblies.nil?
    assemblies = FileList["**/*.Tests.dll"]
    filelist = assemblies.map { |assembly| File.join(Dir.pwd, assembly)}
  end

  test_runner :tests do |tests|
    tests.files = filelist
    tests.exe = 'C:/Program Files (x86)/Microsoft Visual Studio 14.0/Common7/IDE/CommonExtensions/Microsoft/TestWindow/VSTest.console.exe'
    tests.add_parameter '/InIsolation'
    tests.add_parameter '/Logger:trx'
    tests.add_parameter "/Settings:#{Dir.pwd}/#{settings}.runsettings"
  end

end