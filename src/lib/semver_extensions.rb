class SemVerMetadata
  
  def initialize file
    @assemblies = []
    @files = []
    @depends = {}
    parse file
  end

  def assemblies
    @assemblies
  end

  def files
    @files
  end

  def depends
    @depends
  end

  def parse file

    semver = SemVer.new
    semver.load file

    return if semver.metadata == ''

    parts = semver.metadata.split('|')

    return if parts.length < 1

    proj_lines = parts[0].split(',')
    proj_lines.each {|line|
      @assemblies << line.strip
    }

    return if parts.length < 2
    
    folders = parts[1].split(',')
    folders.each { |f|
      @files << File.join(Dir.pwd, "#{f}/*")
    }

    return if parts.length < 3

    @depends = JSON.parse parts[2]

  end

end