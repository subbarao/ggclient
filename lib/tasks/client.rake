require 'bundler'
require_relative '../ggclient/github_gem_builder'
require_relative '../ggclient/client'

namespace :gemserver do
  def ask message
    print message
    STDIN.gets.chomp
  end

  def gem_client
    GemUploader::GeminaboxClient.new
  end

  def query_remote_specs
    source = Bundler::Source::Rubygems.new
    source.add_remote("http://localhost:9292/")
    source.send(:remote_specs)
  end

  def query_local_specs
    Bundler.setup.requested_specs
  end

  def missing_local_specs
    remote_specs = query_remote_specs
    query_local_specs.reject { |r| remote_specs.search(r).first }
  end

  namespace :clear do
    desc "clear all installed gems from gemserver"
    task :all do
      puts "removing all installed gems from gem server"
      if ask('please confirm by entering Y:  ') == 'Y'
        gem_client.clear
        puts "completed"
      else
        puts "aborted"
      end
    end

    desc "clear requested from gemserver"
    task :one do
      client = gem_client
      gemname = ask('enter complete gem name with version:  ')
      client.delete(gemname)
    end
  end

  desc "checks gemserver has all the gems in Gemfile"
  task :check do
    required = missing_local_specs
    #need to find why bundler is gobbled
    required = required.reject { |r| r.name == "bundler" }

    if required.any?
      puts "missing gems:"
      required.each { | s | puts "#{s.name} (#{s.version})" }
    else
      puts "all gems are present on gem server"
    end
  end


  desc "send installed gems to remote gemserver"
  task :install do
    client = gem_client
    missing_local_specs.each do | spec |

      source = spec.source

      installed_gem = if source.respond_to?(:cached_gem, true)
                      source.send(:cached_gem, spec)
                    else
                      GemUploader::GithubGemBuilder.new(spec).generated_gem
                    end

      client.push(installed_gem)
    end
  end
end
