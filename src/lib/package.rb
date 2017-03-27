def nuget_pack id, config, artifact_path
  require 'albacore/task_types/nugets_pack'

  p = Albacore::NugetsPack::Config.new

  p.configuration = config[:build_config]

  if config.has_key? :nuspec && config[:nuspec] != ''
    p.nuspec = config[:nuspec]
  else
    if !config.has_key? :projects || config[:projects] == ''
      raise 'At least one project is required to build'.red
    else
      p.files = config[:projects]
    end
    
    p.with_package do |p|
      if config.has_key? :files
        config[:files].each { |folder, files|
          files.map!{ |x| 
            "#{config[:path]}/#{config[:company]}.#{x}".expand_with(['dll','pdb','xml'])
          }
          files = files.flatten

          files.each{ |file|
            p.add_file file, folder
          }
        }
      end
    end
  end

  p.out = artifact_path

  p.with_metadata do |m|
    m.id = id
    m.title = config[:title]
    m.description = config[:description]
    m.copyright = config[:copyright]
    m.authors = config[:authors]
    m.version = config[:version]
    if config.has_key? :dependencies
      config[:dependencies].each { |name, version|
        m.add_dependency name, version
      }
    end
    if config.has_key? :framework_dependencies
      config[:framework_dependencies].each { |name, version|
        m.add_framework_dependency name, version
      }
    end 
  end
 
  p.target = config[:target_framework]
  
  #p.gen_symbols
  p.nuget_gem_exe

  #p.leave_nuspec
  puts 'Nuget configuration set complete. Creating nuget...'
  Albacore::NugetsPack::ProjectTask.new(p.opts).execute
  puts 'Nuget created'

end
