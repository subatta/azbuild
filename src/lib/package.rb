def nuget_pack id, config, artifact_path
  require 'albacore/task_types/nugets_pack'

  p = Albacore::NugetsPack::Config.new

  p.configuration = BUILD_CONFIG

  if !config.has_key? :projects || config[:projects] == ''
    raise 'At least one project is required to build'.red
  end

  p.files = config[:projects]

  if config.has_key? :nuspec && config[:nuspec] != ''
    p.nuspec = config[:nuspec]
  end

  p.out = artifact_path

  p.with_metadata do |m|
    m.id = id
    m.title = PRODUCT
    m.description = PRODUCT_DESCRIPTION
    m.authors = COMPANY
    m.version = config[:version]
    if config.has_key? :dependencies
      config[:dependencies].each { |name, version|
        m.add_dependency name, version
      }
    end
  end

  p.target = config[:target_framework]
  p.with_package do |p|
    if config.has_key? :files
      config[:files].each { |folder, files|
        files.each{ |file|
          p.add_file file, folder
        }
      }
    end
  end
  
  p.gen_symbols
  p.nuget_gem_exe
  #p.leave_nuspec

  Albacore::NugetsPack::ProjectTask.new(p.opts).execute
end

def nuget_content nuget_name, path, dotnet_ver

  content = {}

  metadata = SemVerMetadata.new ".semver/#{nuget_name}.semver"

  content[:files] = {}
  content[:files]['lib'] = metadata.files

  file_names = metadata.assemblies.map{ |x|
    "#{path}/#{x}"
  }
  assemblies = []
  file_names.each{ |file|
    assemblies.concat(file.expand_with(['dll','pdb','xml']))
  }
  content[:files]['lib'].concat assemblies

  content[:dependencies] = metadata.depends

  content[:version] = read_versions[nuget_name][:nuget_version]
  content[:target_framework] = dotnet_ver

  content
end

