use Rack::ShowException

require ::File.expand_path('../config/config',  __FILE__)
run Divergence::Application.new()