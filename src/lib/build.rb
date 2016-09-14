
def copy_output_files fromDir, filePattern, outDir
  FileUtils.mkdir_p outDir unless exists?(outDir)
  Dir.glob(File.join(fromDir, filePattern)){|file|
    copy(file, outDir) if File.file?(file)
  }
end

def project_outputs props
  props[:projects].map{ |p| "src/#{p}/bin/#{BUILD_CONFIG}/#{p}.dll" }.
    concat( props[:projects].map{ |p| "src/#{p}/bin/#{BUILD_CONFIG}/#{p}.exe" } ).
    find_all{ |path| exists?(path) }
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

def waitfor &block
  checks = 0

  until block.call || checks >10
    sleep 0.5
    checks += 1
  end

  raise 'Waitfor timeout expired. Make sure that you aren\'t ' \
    'running something from the build output folders, or that you ' \
    'have browsed to it through Explorer.'.red if checks > 10
end

def cleantask props

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

def run_vsconsole_tests settings, params = nil, assemblies = nil

  raise 'Settings file name is required' if settings.nil?

  if assemblies.nil?
    assemblies = FileList["**/#{OUTPUT_PATH}/*.Tests.dll"]
    filelist = assemblies.map { |assembly| File.join(Dir.pwd, assembly)}
  end

  test_runner :tests do |tests|
    tests.files = filelist
    tests.exe = 'C:/Program Files (x86)/Microsoft Visual Studio 14.0/Common7/IDE/CommonExtensions/Microsoft/TestWindow/VSTest.console.exe'
    if (params != nil)
      params.each { | p |
        tests.add_parameter p 
      }
    end
    tests.add_parameter '/InIsolation'
    tests.add_parameter '/Logger:trx'
    tests.add_parameter "/Settings:#{Dir.pwd}/#{settings}.runsettings"
  end

end