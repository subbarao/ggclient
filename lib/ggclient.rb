module Ggclient
  class Railtie < ::Rails::Railtie
    rake_tasks do
      load "tasks/client.rake"
    end
  end
end
