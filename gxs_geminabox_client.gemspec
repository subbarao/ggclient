$:.push File.expand_path("../lib", __FILE__)


# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "gxs_geminabox_client"
  s.version     = '0.1.1'
  s.authors     = ["Subba Rao Pasupuleti"]
  s.email       = ["subbarao.pasupuleti@gxs.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of GxsGeminaboxClient."
  s.description = "TODO: Description of GxsGeminaboxClient."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "bundler"
  s.add_dependency "httpclient"
  s.add_dependency 'net-http-persistent'
end
