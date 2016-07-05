require 'bundler/setup'

ENV['RACK_ENV'] = 'test'
$LOAD_PATH.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rack/test'
require 'sinatra/auth/github'
require 'sinatra/auth/github/test/test_helper'
require 'webmock/rspec'

require_relative '../lib/problem_child'
WebMock.disable_net_connect!

RSpec.configure do |config|
  config.include(Sinatra::Auth::Github::Test::Helper)
end

ENV['GITHUB_CLIENT_ID'] = '1234'
ENV['GITHUB_CLIENT_SECRET'] = 'asdf'

def with_env(key, value)
  old_env = ENV[key]
  ENV[key] = value
  yield
  ENV[key] = old_env
end
