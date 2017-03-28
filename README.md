azbuild
========

.Net solutions that are built using the ruby gem [albacore](https://github.com/Albacore/albacore) and use semantic versioning via semver. These scripts tend to have verbosity and bloated rake files with boiler plate code that can be reduced and simplified. There are also configuration transforms that can be applied per deployable environment before projects are built. This gem azbuild provides those functions.

The gem also simplifies ruby version and gem dependencies by bootstrapping itself to detect and install right gem versions. This may soon chnage to use bundler in future.

**Note:** _azbuild_ is the next evolution of _azdeploy_ gem that is available on [rubygems](http://rubygems.org). This gem has been written for .net solutions that need Microsoft Azure service deployments and has support for configuration transforms.

**How to use _azbuild_ gem**

1. install Ruby version 2.3.1-p112 from [RubyInstaller Site](http://rubyinstaller.org)
2. Add gem source (unsecured): `gem sources -a http://rubygems.org`
3. install azbuild - `gem install azbuild`
4. require the azdeploy gem in a blank rake script
5. run rake script

Running the rake script from above will kick-off the install sequence and install all requisite gems. Follow prompts and take appropriate actions like restarting console.

A typical build would perform the following steps:

![](https://github.com/subatta/azbuild/blob/develop/src/images/build_steps.png)

1. Clean solution build output folders
2. Restore nuget packages
3. Version project/s in solution
4. Build
5. Run automated tests
6. Copy build output to specified folders
7. Create nuget packages as specified and copy to artifacts folders
8. Run publish where required (web projects)

An example of tasks and their usage is as follows:

    require 'azbuild'
    
    COMPANY = 'A Company'
    COPYRIGHT = 'Copyright 2016 ' + COMPANY
    PRODUCT = COMPANY + '.AProduct'
    PRODUCT_DESCRIPTION = PRODUCT + ' Library'
    PROJECT_URL = ""
    
    BUILD_CONFIG = 'Release'
    OUTPUT_PATH = 'bin/' + BUILD_CONFIG
    PACKAGES = 'packages'
    
    build_paths = {
      :src => File.expand_path('.'),
      :output => File.expand_path('build_output'),
      :artifacts => File.expand_path('build_artifacts')
    }
    
    outputs = {
      "#{PRODUCT}/#{OUTPUT_PATH}" => "#{PRODUCT}.{dll,pdb,xml}",
    }
    
    nugets = {
      'ALibrary' => {
    :projects => FileList["*/#{PRODUCT}.csproj"],
    :files => {
      'build' => FileList[File.join(Dir.pwd, 'Lib/*')] + [File.join(Dir.pwd, 'ALibrary.targets')]
    },
    :version => read_versions['ALibrary'][:nuget_version]
      }
    }
    
    task :clean do |t|
      puts "Cleaning and creating working directories...".bg_green.white
      cleantask(build_paths)
    end
    
    nugets_restore :restore do |n|
      puts "Restoring missing nuget packages...".bg_green.white
      n.nuget_gem_exe
      n.out = File.expand_path(PACKAGES)
    end
    
    task :versioning do |t|
      puts "Versioning assemblies...".bg_green.white
      update_assembly_versions
    end
    
    build :build do |b|
      puts "Performing build...".bg_green.white
    
      b.logging = 'q'  # q[uiet], m[inimal], n[ormal], d[etailed], and diag[nostic]
      b.target = ['Clean', 'Rebuild']
      b.prop 'Configuration', BUILD_CONFIG
      b.sln = 'Fingerprint.sln'
      b.nologo # no Microsoft/XBuild header output
    end
    
    task :tests do |tests|
      puts "Running the Units Tests for Library...".bg_green.white
      run_vsconsole_tests 'Fingerprint', ['/TestCaseFilter:TestCategory!=Integration']
    end
    
    task :copy_output do
      puts "Copying build output to designated folders...".bg_green.white
      outputs.each { |name, filter|
    copy_output_files File.join(build_paths[:src], name), filter, File.join(build_paths[:output], 'net-4.6')
      }
    end
    
    task :create_nugets do
      puts "Creating the nuget packages and copying them to artifacts...".bg_green.white
      nugets.each { |id, config|
    nuget_pack id, config, build_paths[:artifacts]
      }
    end
    
    desc 'Cleans, versions, compiles the application and generates build_output.'
    task :compile => [:versioning, :build, :tests, :copy_output, :create_nugets]
    
    desc 'Run all build tasks'
    task :default => [:clean, :restore, :compile]
