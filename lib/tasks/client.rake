require 'bundler'
require 'uri'
require 'httpclient'
require 'net/http/persistent'

namespace :gemserver do
  def ask message
    print message
    STDIN.gets.chomp
  end

  def gem_client
    GeminaboxClient.new("http://localhost:9292/")
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
                      GithubGemBuilder.new(spec).generated_gem
                    end

    client.push(installed_gem)
    end
  end
end

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

class GeminaboxClient
  attr_reader :url, :http_client

  def initialize(url)
    extract_username_and_password_from_url!(url)
    @http_client = HTTPClient.new
    @http_client.set_auth(url_for(:upload), @username, @password) if @username or @password
    @http_client.www_auth.basic_auth.challenge(url_for(:upload)) # Workaround: https://github.com/nahi/httpclient/issues/63
    @http_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  def extract_username_and_password_from_url!(url)
    uri = URI.parse(url.to_s)
    @username, @password = uri.user, uri.password
    uri.user = uri.password = nil
    uri.path = uri.path + "/" unless uri.path.end_with?("/")
    @url = uri.to_s
  end

  def url_for(path)
    url + path.to_s
  end

  def clear
    http_client.delete(url_for(:gems))
  end

  def delete(gemname)
    http_client.delete("#{url_for(:gems)}/#{gemname}.gem")
  end

  def find(gemfile)
    puts "querying: #{gemfile}"
    http_client.get(url_for("gems/#{gemfile}.gem")).status == 302
  end

  def push(gemfile)
    puts "uploading: #{File.basename(gemfile)}"
    response = http_client.post(url_for(:upload), {'file' => File.open(gemfile, "rb")}, {'Accept' => 'text/plain'})

    if response.status < 400
      response.body
    else
      puts "Error (#{response.code} received)\n\n#{response.body}"
    end
  end
end
