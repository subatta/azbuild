ASTER = '*'
CSPROJ = '.csproj'

$version_map = {}

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

# read version info from solutioninfo.cs file
def read_solution_version
  version = ''
  File.open('SolutionInfo.cs', 'r').each_line do |line|
    if line.include?('AssemblyVersion')
      version = line[/\(.*?\)/]
      break
    end
  end
  ver = SemVer.parse version
  
  $version_map[ASTER] = versions(ver, &method(:commit_data))

  $version_map
end

# put semver versions in a map
def read_versions

  return $version_map if !$version_map.empty?
  
  files = Dir['.semver/**/*.semver']
  files.each { | file |
    v = SemVer.new
    v.load file
    v.patch = (ENV['BUILD_NUMBER'] || v.patch).to_i
    version = versions(v, &method(:commit_data))

    sm = SemVerMetadata.new file
    assemblies = sm.assemblies
    sm.assemblies.each { |a|
      $version_map[a] = version
    }

    name = file
      .gsub(/.semver/, '')
      .gsub('/', '')

    $version_map[name] = version
  }

  # this is for assemblies not versioned with semver
  $version_map[ASTER] = versions_no_semver(&method(:commit_data))

  $version_map
end

def update_assembly_versions
  require 'albacore/task_types/asmver'

  $version_map = read_versions

  files = FileList['**/*' + CSPROJ]
  files.each { |f|
      
    ns =  File.basename(f, CSPROJ)

    asm_file = File.join File.dirname(f), '/Properties/AssemblyVersion.cs'
    next if ns.nil? || ns.to_s == '' || !File.file?(asm_file)

    c = Albacore::Asmver::Config.new
    c.file_path = asm_file

    if ($version_map.key? ns)
      c.attributes assembly_configuration: BUILD_CONFIG,
            assembly_version: $version_map[ns][:long_version],
            assembly_file_version: $version_map[ns][:long_version],
            assembly_informational_version: $version_map[ns][:build_version]
    else 
      c.attributes assembly_configuration: BUILD_CONFIG,
            assembly_version: $version_map[ASTER][:long_version],
            assembly_file_version: $version_map[ASTER][:long_version],
            assembly_informational_version: $version_map[ASTER][:build_version]
    end
    
    Albacore::Asmver::Task.new(c.opts).execute
  }
end

def self.versions semver, &commit_data
  {
    # just a monotonic inc
    :build_number   => semver.patch,
    :semver         => semver,

    # purely M.m.p format
    :formal_version => "#{ XSemVer::SemVer.new(semver.major, semver.minor, semver.patch).format "%M.%m.%p"}",

    # four-numbers version, useful if you're dealing with COM/Windows
    :long_version   => "#{semver.format '%M.%m.%p'}.0",

    # extensible number w/ git hash
    :build_version  => semver.format("%M.%m.%p%s") + ".#{yield[0]}",

    # nuget (not full semver 2.0.0 support) see http://nuget.codeplex.com/workitem/1796
    :nuget_version  => format_nuget(semver)
  }
end

def self.versions_no_semver &commit_data
  dt_ver = Time.new.strftime('%y.%-m.%-d') + ".#{(ENV['BUILD_NUMBER'] || '0')}"
  {

    :formal_version => dt_ver,

    # four-numbers version, useful if you're dealing with COM/Windows
    :long_version   => dt_ver,

    # extensible number w/ git hash
    :build_version  => dt_ver + ".#{yield[0]}"
  }
end

def self.format_nuget semver
  if semver.prerelease and not semver.prerelease.empty?
    "#{semver.major}.#{semver.minor}.#{semver.patch}-#{semver.prerelease.gsub(/\W/, '')}"
  else
    semver.format '%M.%m.%p'
  end
end

# load the commit data
# returns: [short-commit :: String, date :: DateTime]
def self.commit_data
  begin
    commit = `git rev-parse --short HEAD`.chomp()[0,6]
    git_date = `git log -1 --date=iso --pretty=format:%ad`
    commit_date = DateTime.parse( git_date ).strftime("%Y-%m-%d %H:%M:%S")
  rescue
    commit = (ENV['BUILD_VCS_NUMBER'] || "000000")[0,6]
    commit_date = Time.new.strftime("%Y-%m-%d %H:%M:%S")
  end
  [commit, commit_date]
end