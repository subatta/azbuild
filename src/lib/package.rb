=begin
desc "Builds the nuget package"
task :package => [:versioning, :create_nuspec] do
  sh "#{NUGET} pack #{build_paths[:artifacts]}/#{PRODUCT}.Framework.nuspec /Symbols /OutputDirectory #{build_paths[:artifacts]}"
  sh "#{NUGET} pack #{build_paths[:artifacts]}/#{PRODUCT}.Framework.Web.nuspec /Symbols /OutputDirectory #{build_paths[:artifacts]}"
  sh "#{NUGET} pack #{build_paths[:artifacts]}/#{PRODUCT}.Framework.Messaging.nuspec /Symbols /OutputDirectory #{build_paths[:artifacts]}"
  sh "#{NUGET} pack #{build_paths[:artifacts]}/#{PRODUCT}.Contracts.nuspec /Symbols /OutputDirectory #{build_paths[:artifacts]}"
  sh "#{NUGET} pack #{build_paths[:artifacts]}/#{PRODUCT}.Identity.nuspec /Symbols /OutputDirectory #{build_paths[:artifacts]}"
  sh "#{NUGET} pack #{build_paths[:artifacts]}/#{PRODUCT}.Test.nuspec /Symbols /OutputDirectory #{build_paths[:artifacts]}"
  sh "#{NUGET} pack #{build_paths[:artifacts]}/#{PRODUCT}.Test.Messaging.nuspec /Symbols /OutputDirectory #{build_paths[:artifacts]}"
  sh "#{NUGET} pack #{build_paths[:artifacts]}/#{PRODUCT}.Management.nuspec /Symbols /OutputDirectory #{build_paths[:artifacts]}"
  sh "#{NUGET} pack #{build_paths[:artifacts]}/#{PRODUCT}.Management.Tools.nuspec /Symbols /OutputDirectory #{build_paths[:artifacts]}"
end

task :create_nuspec => [:contracts_nuspec, :framework_nuspec, :frameworkweb_nuspec, :frameworkmsg_nuspec, :identity_nuspec ,:test_nuspec, :test_messaging_nuspec, :management_nuspec, :management_tools_nuspec]

LANG = 'en-US'
SRC_FOLDER = 'src'
FALSE_STR = 'false'

nuspec :framework_nuspec do |nuspec|
  nuspec.id = "#{PRODUCT}.Framework"
  nuspec.version = ENV['NUGET_VERSION']
  nuspec.authors = COMPANY
  nuspec.description = "#{PRODUCT_DESCRIPTION} Development Framework"
  nuspec.title = "#{PRODUCT}.Framework"
  nuspec.projectUrl = PROJECT_URL
  nuspec.language = LANG
  nuspec.requireLicenseAcceptance = FALSE_STR
  nuspec.dependency "Google.ProtocolBuffers", "[2.4.1.521]"
  nuspec.output_file = File.join(build_paths[:artifacts], "#{PRODUCT}.Framework.nuspec")
  add_files build_paths[:output], "#{PRODUCT}.Framework.{dll,pdb,xml}", nuspec
  nuspec.file(File.join(build_paths[:src], "#{PRODUCT}.Framework\\**\\*.cs").gsub("/","\\"), SRC_FOLDER)
end

nuspec :frameworkweb_nuspec do |nuspec|
  nuspec.id = "#{PRODUCT}.Framework.Web"
  nuspec.version = ENV['NUGET_VERSION']
  nuspec.authors = COMPANY
  nuspec.description = "#{PRODUCT_DESCRIPTION} Development Framework for Web Applications"
  nuspec.title = "#{PRODUCT}.Framework.Web"
  nuspec.projectUrl = PROJECT_URL
  nuspec.language = LANG
  nuspec.requireLicenseAcceptance = FALSE_STR
  nuspec.dependency "Google.ProtocolBuffers", "[2.4.1.521]"
  nuspec.dependency "#{PRODUCT}.Framework", ENV['NUGET_VERSION']
  nuspec.dependency "Newtonsoft.Json", "[6.0.8]"
  nuspec.dependency "Microsoft.AspNet.WebApi.Client", "[5.2.3]"
  nuspec.dependency "Microsoft.AspNet.WebApi.Core", "[5.2.3]"
  nuspec.output_file = File.join(build_paths[:artifacts], "#{PRODUCT}.Framework.Web.nuspec")
  add_files build_paths[:output], "#{PRODUCT}.Framework.Web.{dll,pdb,xml}", nuspec
  nuspec.file(File.join(build_paths[:src], "#{PRODUCT}.Framework.Web\\**\\*.cs").gsub("/","\\"), SRC_FOLDER)
end

nuspec :frameworkmsg_nuspec do |nuspec|
  nuspec.id = "#{PRODUCT}.Framework.Messaging"
  nuspec.version = ENV['NUGET_VERSION']
  nuspec.authors = COMPANY
  nuspec.description = "#{PRODUCT_DESCRIPTION} Development Framework for Messaging Services"
  nuspec.title = "#{PRODUCT}.Framework.Messaging"
  nuspec.projectUrl = PROJECT_URL
  nuspec.language = LANG
  nuspec.requireLicenseAcceptance = FALSE_STR
  nuspec.dependency "Google.ProtocolBuffers", "[2.4.1.521]"
  nuspec.dependency "#{PRODUCT}.Framework", ENV['NUGET_VERSION']
  nuspec.dependency "Newtonsoft.Json", "[6.0.8]"
  nuspec.dependency "MassTransit", "[3.0.14]"
  nuspec.dependency "NewId", "2.1.3"
  nuspec.output_file = File.join(build_paths[:artifacts], "#{PRODUCT}.Framework.Messaging.nuspec")
  add_files build_paths[:output], "#{PRODUCT}.Framework.Messaging.{dll,pdb,xml}", nuspec
  nuspec.file(File.join(build_paths[:src], "#{PRODUCT}.Framework.Messaging\\**\\*.cs").gsub("/","\\"), SRC_FOLDER)
end

nuspec :contracts_nuspec do |nuspec|
  nuspec.id = "#{PRODUCT}.Contracts"
  nuspec.version = ENV['NUGET_VERSION']
  nuspec.authors = COMPANY
  nuspec.description = "#{PRODUCT_DESCRIPTION} Command and Event Contracts"
  nuspec.title = "#{PRODUCT}.Contracts"
  nuspec.projectUrl = PROJECT_URL
  nuspec.language = LANG
  nuspec.requireLicenseAcceptance = FALSE_STR
  nuspec.output_file = File.join(build_paths[:artifacts], "#{PRODUCT}.Contracts.nuspec")
  add_files build_paths[:output], "#{PRODUCT}.Contracts.{dll,pdb,xml}", nuspec
  nuspec.file(File.join(build_paths[:src], "#{PRODUCT}.Contracts\\**\\*.cs").gsub("/","\\"), SRC_FOLDER)
end

nuspec :identity_nuspec do |nuspec|
  nuspec.id = "#{PRODUCT}.Identity"
  nuspec.version = ENV['NUGET_VERSION']
  nuspec.authors = COMPANY
  nuspec.description = "#{PRODUCT_DESCRIPTION} Framework Identity"
  nuspec.title = "#{PRODUCT}.Identity"
  nuspec.projectUrl = PROJECT_URL
  nuspec.language = LANG
  nuspec.requireLicenseAcceptance = FALSE_STR
  nuspec.dependency "Google.ProtocolBuffers", "[2.4.1.521]"
  nuspec.dependency "#{PRODUCT}.Framework", ENV['NUGET_VERSION']
  nuspec.dependency "#{PRODUCT}.Framework.Messaging", ENV['NUGET_VERSION']
  nuspec.dependency "MassTransit", "3.0.14"
  nuspec.output_file = File.join(build_paths[:artifacts], "#{PRODUCT}.Identity.nuspec")
  add_files build_paths[:output], "#{PRODUCT}.Identity.{dll,pdb,xml}", nuspec
  nuspec.file(File.join(build_paths[:src], "#{PRODUCT}.Identity\\**\\*.cs").gsub("/","\\"), SRC_FOLDER)
end

nuspec :test_nuspec do |nuspec|
  nuspec.id = "#{PRODUCT}.Test"
  nuspec.version = ENV['NUGET_VERSION']
  nuspec.authors = COMPANY
  nuspec.description = "#{PRODUCT_DESCRIPTION} Development Framework - Unit Test Edition"
  nuspec.title = "#{PRODUCT}.Test"
  nuspec.projectUrl = PROJECT_URL
  nuspec.language = LANG
  nuspec.requireLicenseAcceptance = FALSE_STR
  nuspec.dependency "#{PRODUCT}.Framework", ENV['NUGET_VERSION']
  nuspec.dependency "#{PRODUCT}.Identity", ENV['NUGET_VERSION']
  nuspec.dependency "#{PRODUCT}.Contracts", ENV['NUGET_VERSION']
  nuspec.dependency "Google.ProtocolBuffers", "[2.4.1.521]"
  nuspec.dependency "Autofac", "[3.5.2]"
  nuspec.dependency "Fooidity", "[1.0.1]"
  nuspec.dependency "Fooidity.Autofac", "[1.0.1]"
  nuspec.dependency "NUnit", "[2.6.4]"
  nuspec.dependency "#{COMPANY}.Shared", "1.9.0"
  nuspec.dependency "NewId", "2.1.3"
  nuspec.dependency "WindowsAzure.Storage", "4.3.0"
  nuspec.dependency "Microsoft.Data.Edm", "5.6.2"
  nuspec.dependency "Microsoft.Data.OData", "5.6.2"
  nuspec.dependency "Newtonsoft.Json", "[6.0.8]"
  nuspec.output_file = File.join(build_paths[:artifacts], "#{PRODUCT}.Test.nuspec")
  add_files build_paths[:output], "#{PRODUCT}.Test.{dll,pdb,xml}", nuspec
  add_files build_paths[:output], "#{PRODUCT}.Core.{dll,pdb,xml}", nuspec
  add_files build_paths[:output], "#{PRODUCT}.Storage.{dll,pdb,xml}", nuspec
  add_files build_paths[:output], "#{PRODUCT}.Runtime.{dll,pdb,xml}", nuspec
  nuspec.file(File.join(build_paths[:src], "#{PRODUCT}.Test\\**\\*.cs").gsub("/","\\"), SRC_FOLDER)
end

nuspec :test_messaging_nuspec do |nuspec|
  nuspec.id = "#{PRODUCT}.Test.Messaging"
  nuspec.version = ENV['NUGET_VERSION']
  nuspec.authors = COMPANY
  nuspec.description = "#{PRODUCT_DESCRIPTION} Development Framework - Messaging Unit Testing"
  nuspec.title = "#{PRODUCT}.Test.Messaging"
  nuspec.projectUrl = PROJECT_URL
  nuspec.language = LANG
  nuspec.requireLicenseAcceptance = FALSE_STR
  nuspec.dependency "#{PRODUCT}.Test", ENV['NUGET_VERSION']
  nuspec.dependency "#{PRODUCT}.Framework.Messaging", ENV['NUGET_VERSION']
  nuspec.dependency "MassTransit", "3.0.14"
  nuspec.dependency "MassTransit.TestFramework", "3.0.14"
  nuspec.output_file = File.join(build_paths[:artifacts], "#{PRODUCT}.Test.Messaging.nuspec")
  add_files build_paths[:output], "#{PRODUCT}.Test.Messaging.{dll,pdb,xml}", nuspec
  add_files build_paths[:output], "#{PRODUCT}.Runtime.{dll,pdb,xml}", nuspec
  nuspec.file(File.join(build_paths[:src], "#{PRODUCT}.Test.Messaging\\**\\*.cs").gsub("/","\\"), SRC_FOLDER)
end

nuspec :management_nuspec do |nuspec|
  nuspec.id = "#{PRODUCT}.Management"
  nuspec.version = ENV['NUGET_VERSION']
  nuspec.authors = COMPANY
  nuspec.description = "#{PRODUCT_DESCRIPTION} Management Library"
  nuspec.title = "#{PRODUCT}.Management"
  nuspec.projectUrl = PROJECT_URL
  nuspec.language = LANG
  nuspec.requireLicenseAcceptance = FALSE_STR
  nuspec.dependency "#{PRODUCT}.Framework", ENV['NUGET_VERSION']
  nuspec.dependency "#{PRODUCT}.Identity", ENV['NUGET_VERSION']
  nuspec.dependency "Microsoft.IdentityModel.Clients.ActiveDirectory", "[2.14.201151115]"
  nuspec.dependency "MassTransit", "3.0.14"
  nuspec.dependency "Autofac", "[3.5.2]"
  nuspec.dependency "Fooidity", "[1.0.1]"
  nuspec.dependency "Fooidity.Autofac", "[1.0.1]"
  nuspec.output_file = File.join(build_paths[:artifacts], "#{PRODUCT}.Management.nuspec")
  add_files build_paths[:output], "#{PRODUCT}.Core.{dll,pdb,xml}", nuspec
  add_files build_paths[:output], "#{PRODUCT}.Storage.{dll,pdb,xml}", nuspec
  add_files build_paths[:output], "#{PRODUCT}.Management.{dll,pdb,xml}", nuspec
  nuspec.file(File.join(build_paths[:src], "#{PRODUCT}.Management\\**\\*.cs").gsub("/","\\"), SRC_FOLDER)
end

nuspec :management_tools_nuspec do |nuspec|
  nuspec.id = "#{PRODUCT}.Management.Tools"
  nuspec.version = ENV['NUGET_VERSION']
  nuspec.authors = COMPANY
  nuspec.description = "#{PRODUCT_DESCRIPTION} Management Tools Library"
  nuspec.title = "#{PRODUCT}.Management.Tools"
  nuspec.projectUrl = PROJECT_URL
  nuspec.language = LANG
  nuspec.requireLicenseAcceptance = FALSE_STR
  nuspec.dependency "Autofac", "3.5.2"
  nuspec.dependency "Fooidity", "1.0.1"
  nuspec.output_file = File.join(build_paths[:artifacts], "#{PRODUCT}.Management.Tools.nuspec")
  tools_path = File.expand_path(File.join(build_paths[:src] ,"#{PRODUCT}.Management", "Tools"))
  nuspec.file(File.join(tools_path, "*.ps*").gsub("/","\\"), "tools")
  add_files build_paths[:output], "#{PRODUCT}.Management.{dll,pdb,xml}", nuspec
  add_files build_paths[:output], "#{PRODUCT}.Framework.{dll,pdb,xml}", nuspec
  add_files build_paths[:output], "Microsoft.IdentityModel.Clients.ActiveDirectory.dll", nuspec
  add_files build_paths[:output], "*.dll", nuspec, 'tools'
  add_files build_paths[:output], 'dpm.{exe,exe.config}', nuspec, 'tools'
end=end
