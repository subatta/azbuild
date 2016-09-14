class SemVerMetadata
  
  def self.projects file

      projects = []
      semver = SemVer.new
      semver.load file

      proj_lines = semver.metadata.split(',')
      proj_lines.each {|line|
        projects.push line.strip
      }

      projects

  end

end