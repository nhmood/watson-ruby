lib = File.expand_path(File.dirname(__FILE__) + '/../lib')
begin
  require 'watson'
rescue LoadError
  $LOAD_PATH << lib
  require 'watson'
end

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

Rspec.configure do |config|
  config.include OutputHelper
  config.order = :random
  config.run_all_when_everything_filtered = true
end
