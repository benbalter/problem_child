# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'problem_child/version'

Gem::Specification.new do |spec|
  spec.name          = "problem_child"
  spec.version       = ProblemChild::VERSION
  spec.authors       = ["Ben Balter"]
  spec.email         = ["ben.balter@github.com"]
  spec.summary       = "Allows authenticated or anonymous users to fill out a standard web form to creat GitHub issues."
  spec.homepage      = "https://github.com/benbalter/problem_child"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra", "~> 1.4"
  spec.add_dependency "octokit", "~> 3.7"
  spec.add_dependency "dotenv", "~> 1.0"
  spec.add_dependency "rack-ssl-enforcer", "~> 0.2"
  spec.add_dependency "sinatra_auth_github", "~> 1.0"
  spec.add_dependency "activesupport", "~> 4.2"
  spec.add_dependency "rack", "1.6"
  spec.add_dependency "redis", "~> 3.2"
  spec.add_dependency "moneta", "~> 0.8"

  spec.add_development_dependency "rspec", "~> 3.1"
  spec.add_development_dependency "rack-test", "~> 0.6"
  spec.add_development_dependency "webmock", "~> 1.2 "
  spec.add_development_dependency "foreman", "~> 0.77"
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake", "~> 10.4"
  spec.add_development_dependency "pry", "~> 0.10"
end
