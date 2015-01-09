require 'octokit'
require 'sinatra'
require 'sinatra_auth_github'
require 'dotenv'
require 'json'
require 'active_support'
require 'active_support/core_ext/string'
require "problem_child/version"

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

    enable :sessions

    set :github_options, {
      :scopes    => "repo",
      :secret    => ENV['GITHUB_CLIENT_SECRET'],
      :client_id => ENV['GITHUB_CLIENT_ID'],
    }

    register Sinatra::Auth::Github

    use Rack::Session::Cookie, {
      :http_only => true,
      :secret    => SecureRandom.hex
    }

    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    set :views, Proc.new { ProblemChild.views_dir }
    set :root, Proc.new { ProblemChild.root }
    set :public_folder, Proc.new { File.expand_path "public", ProblemChild.root }

    def repo
      ENV["GITHUB_REPO"]
    end

    def user
      env['warden'].user unless env['warden'].nil?
    end

    def anonymous_submissions?
      ENV["GITHUB_TOKEN"] && !ENV["GITHUB_TOKEN"].empty?
    end

    def token
      if anonymous_submissions?
        ENV["GITHUB_TOKEN"]
      elsif !user.nil?
        user.token
      end
    end

    def client
      @client ||= Octokit::Client.new :access_token => token
    end

    def render_template(template, locals={})
      halt erb template, :layout => :layout, :locals => locals.merge({ :template => template })
    end

    def issue_body
      form_data.reject { |key, value| key == "title" }.map { |key,value| "* **#{key.humanize}**: #{value}"}.join("\n")
    end

    # abstraction to allow cached form data to be used in place of default params
    def form_data
      session["form_data"].nil? ? params : JSON.parse(session["form_data"])
    end

    def create_issue(data=params)
      client.create_issue(repo, form_data["title"], issue_body)
    end

    def auth!
      if anonymous_submissions?
        true
      elsif ENV['GITHUB_TEAM_ID']
        github_team_authenticate!(ENV['GITHUB_TEAM_ID'])
      elsif ENV['GITHUB_ORG_ID']
        github_organization_authenticate!(ENV['GITHUB_ORG_ID'])
      else
        raise "Must define GITHUB_TEAM_ID, GITHUB_ORG_ID, OR GITHUB_TOKEN"
        halt 401
      end
    end

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
      if anonymous_submissions?
        create_issue
      else
        session[:form_data] = params.to_json
        auth!
      end
    end
  end
end

Dotenv.load unless ProblemChild::App.production?
