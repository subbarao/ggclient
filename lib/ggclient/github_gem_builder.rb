module Ggclient
  class GithubGemBuilder
    def initialize(gem_installer)
      @gem_installer = gem_installer
    end

    def gemspec_name
      File.basename(Dir.glob(File.join(@gem_installer.gem_dir, "*.gemspec")).first)
    end

    def generated_gem
      unless Dir.glob(File.join(@gem_installer.gem_dir, "*.gem")).first
        `cd #{@gem_installer.gem_dir} && gem build #{gemspec_name}`
      end

      Dir.glob(File.join(@gem_installer.gem_dir, "*.gem")).first
    end
  end
end
