azbuild
========

.Net solutions that are built using the ruby gem albacore and use semantic versioning via semver have verbosity and bloated rake files with some boiler plate that can be reduced and simplified. There are also configuration transforms that can be applied per deployable environment before projects are built. This gem azbuild provides those functions.

The gem also simplifies ruby version and gem dependencies by bootstrapping itself to detect and install right gem versions. This may soon chnage to use bundler in future.

<b>Note: </b>azbuild is the next evolution of <b>azdeploy</b> gem that is available on http://rubygems.org

<b>Where do configuration values come from?</b>

Currently, configuration key value pairs for specific transforms are stored and retrived from an Azure Table using azure ruby gem. More transforms can be added as well as other configuration sources

<b>How to use the gem</b>

azbuild is in development and you'll need to use azdeploy until azbuild development is complete.

To start using azdeploy, 

1. install Ruby version 2.0.0p481
2. install azdeploy from http://rubygems.org
3. require the azdeploy gem in a blank rake script
4. run rake script

Running the rake script from above will kick-off the install sequence and install all requisite gems. Follow prompts and take appropriate actions like restarting console.

A typical build would perform the following steps:

1. clean solution build output folders
2. transform configuration
3. restore nuget packages
4. build the solution
5. run unit tests
6. copy build output to specified folders
7. create nuget packages as specified and copy to artifacts folders
8. run publish where required (web projects)

Few examples of tasks and their usage is as follows:

```
desc 'Prepares the working directory for a new build'
task :clean do
  cleantask(BUILD_PATHS)
end

desc 'Transform Configuration'
task :transform_config do
    Transform.new.transform([''])
end

desc 'restores missing packages'
task :restore do
    restore_nuget(NUGET)   # path of nuget exe
end

desc 'Only compiles the application.'
msbuild :build do |msb|
  msb.targets :Clean, :Build 
  clean_build(msb, "src/#{PRODUCT}.sln")
end

desc "Publishes."
msbuild :publish do |msb|
  msb.targets :Publish
  clean_build(msb, "src/#{PRODUCT}.sln")
end

desc 'Running rake for each sub project'
task :package do
   
end

desc 'Copies build output to designated folders.'
task :copy_output do
  outputs.each { |name, filter|
    copy_output_files File.join(BUILD_PATHS[:src], name), filter, File.join(BUILD_PATHS[:output], 'net-4.5')
  }
end

desc 'Cleans, versions, compiles the application and generates build_output.'
task :compile => [:build, :tests, :copy_output]

desc '**Default**, compiles and runs tests'
task :default => [:clean, :transform_config, :restore, :compile, :package, :publish]

```

Instructions for azbuild when it's ready:

1. Install latest version of Ruby
2. Install the gem from http://rubygems.org
3. Run bundle update
4. require gem in a rake script and start using available methods