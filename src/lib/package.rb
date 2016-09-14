def nuget_pack id, config, artifact_path
  require 'albacore/task_types/nugets_pack'

  p = Albacore::NugetsPack::Config.new

  p.configuration = BUILD_CONFIG

  if !config.has_key? :projects || config[:projects] == ''
    raise 'At least one project is required to build'.red
  end
  if config[:projects] != ''
    p.files = config[:projects]
  end
  if config.has_key? :nuspec && config[:nuspec] != ''
    p.nuspec   = config[:nuspec]
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

  Albacore::NugetsPack::ProjectTask.new(p.opts).execute
end