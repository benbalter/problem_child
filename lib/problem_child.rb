require 'octokit'
require 'sinatra'
require 'sinatra_auth_github'
require 'dotenv'
require 'json'
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

  class App < Sinatra::Base

    include ProblemChild::Helpers

    set :github_options, {
      :scopes    => "repo"
    }

    register Sinatra::Auth::Github

    enable :sessions
    use Rack::Session::Cookie, {
      :http_only => true,
      :secret    => SecureRandom.hex
    }

    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    set :views, Proc.new { ProblemChild.views_dir }
    set :root,  Proc.new { ProblemChild.root }
    set :public_folder, Proc.new { File.expand_path "public", ProblemChild.root }

    get "/" do
      if session[:form_data]
        flash = :success if create_issue
        session[:form_data] = nil
      else
        flash = nil
        auth!
      end
      halt erb :form, :layout => :layout, :locals => { :repo => repo, :anonymous => anonymous_submissions?, :flash => flash }
    end

    post "/" do
      session[:form_data] = params.to_json
      auth! unless anonymous_submissions?      
      halt redirect "/"
    end
  end
end

Dotenv.load unless ProblemChild::App.production?
