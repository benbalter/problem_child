require 'octokit'
require 'sinatra'
require 'sinatra_auth_github'
require 'dotenv'
require 'json'
require 'redis'
require 'rack/session/moneta'
require 'active_support'
require 'active_support/core_ext/string'
require "problem_child/version"
require "problem_child/helpers"

module ProblemChild

  def self.root
    File.expand_path "./problem_child", File.dirname(__FILE__)
  end

  def self.views_dir
    @views_dir ||= File.expand_path "views", ProblemChild.root
  end

  def self.views_dir=(dir)
    @views_dir = dir
  end

  def self.public_dir
    @public_dir ||= File.expand_path "public", ProblemChild.root
  end

  def self.public_dir=(dir)
    @public_dir = dir
  end

  class App < Sinatra::Base

    include ProblemChild::Helpers

    set :github_options, {
      :scopes => "repo,read:org"
    }

    if ENV["REDIS_URL"] && !ENV["REDIS_URL"].to_s.empty?
      use Rack::Session::Moneta, store: :Redis, url: ENV["REDIS_URL"]
    else
      use Rack::Session::Cookie, {
        http_only: true,
        secret:    ENV['SESSION_SECRET'] || SecureRandom.hex
      }
    end

    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    ENV['WARDEN_GITHUB_VERIFIER_SECRET'] ||= SecureRandom.hex
    register Sinatra::Auth::Github

    set :views, Proc.new { ProblemChild.views_dir }
    set :root,  Proc.new { ProblemChild.root }
    set :public_folder, Proc.new { ProblemChild.public_dir }

    get "/" do
      flash = nil
      issue = nil
      access = false

      if session[:form_data]
        if issue_title.empty?
          flash = 'Please enter a title.'
        else
          issue = uploads.empty? ? create_issue : create_pull_request
          session[:form_data] = nil
          access = repo_access?
        end
      else
        auth!
      end

      halt erb :form, :layout => :layout, :locals => { :repo => repo, :anonymous => anonymous_submissions?, :flash => flash, :issue => issue, :access => access }
    end

    post "/" do
      cache_form_data
      auth! unless anonymous_submissions?
      halt redirect "/"
    end
  end
end

Dotenv.load unless ProblemChild::App.production?
