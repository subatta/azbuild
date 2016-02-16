def auto_add_dependencies(project)
  @Dependencies = Array.new

  each_package_dependency(project) do |package|
    yield package
  end

  return @Dependencies
end


def each_package_dependency(project)
  packages_config = File.join File.dirname(project), 'packages.config'
  return [] unless File.exists? packages_config

  each_package packages_config do |id, version|
    yield Dependency.new id, version
  end
end


def each_package(packages_config)
  xml = File.read packages_config
  doc = REXML::Document.new xml
  doc.elements.each 'packages/package' do |package|
    if block_given?
      yield package.attributes['id'], package.attributes['version']
    else
      "no package block"
    end
  end
end


class Dependency
  attr_accessor :Name, :Version

  def initialize(name, version)
    @Name = name
    @Version = version
  end
end
