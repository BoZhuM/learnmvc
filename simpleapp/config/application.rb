require 'rubygems'
require 'bundler/setup'

if defined?(Bundler)
  Bundler.require(:default)
end
#加载包括controllers, models等等.
to_require_pattern = File.join(File.dirname(__FILE__), "..", "app", "**", "*.rb")

Dir.glob(to_require_pattern).each do |t|
    require t
end

module Simpleapp
  class Application < Srbmvc::Application
  end
end
