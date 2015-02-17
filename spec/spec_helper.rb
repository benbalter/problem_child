require "bundler/setup"

ENV['RACK_ENV'] = 'test'
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rack/test'
require 'sinatra/auth/github'
require 'sinatra/auth/github/test/test_helper'
require 'webmock/rspec'

require_relative "../lib/problem_child"
WebMock.disable_net_connect!

RSpec.configure do |config|
  config.include(Sinatra::Auth::Github::Test::Helper)
end

def with_env(key, value)
  old_env = ENV[key]
  ENV[key] = value
  yield
  ENV[key] = old_env
end
