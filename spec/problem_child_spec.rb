require "spec_helper"

describe "ProblemChild" do
  it "knows the root" do
   expected = File.expand_path "../lib/problem_child", File.dirname(__FILE__)
   expect(ProblemChild.root).to eql(expected)
  end

  it "knows the views dir" do
   expected = File.expand_path "../lib/problem_child/views", File.dirname(__FILE__)
   expect(ProblemChild.views_dir).to eql(expected)
  end

  it "allows users to set the views dir" do
   old = ProblemChild.views_dir
   ProblemChild.views_dir = "./foo"
   expect(ProblemChild.views_dir).to eql("./foo")
   ProblemChild.views_dir = old
  end
end

describe "logged in user" do

  before(:each) do
    @user = make_user('login' => 'benbaltertest')
    login_as @user

    ENV["GITHUB_TEAM_ID"] = nil
    ENV["GITHUB_ORG_ID"]  = nil
    ENV["GITHUB_TOKEN"]   = nil
    ENV["GITHUB_REPO"]    = nil
  end

  include Rack::Test::Methods

  def app
    ProblemChild::App
  end

  it "shows the securocat when github returns an oauth error" do
    with_env "GITHUB_ORG_ID", "balter-test-org" do
      get "/auth/github/callback?error=redirect_uri_mismatch"
      follow_redirect!
      expect(last_response.body).to match(%r{securocat\.png})
    end
  end

  it "shows the form when properly org auth'd" do
    with_env "GITHUB_ORG_ID", "balter-test-org" do
      stub_request(:get, "https://api.github.com/orgs/balter-test-org/members/benbaltertest").
      to_return(:status => 204)

      get "/"
      expect(last_response.status).to eql(200)
      expect(last_response.body).to match(/Submit an issue/)
    end
  end

  it "shows the form when properly team auth'd" do
    with_env "GITHUB_TEAM_ID", "1234" do
      stub_request(:get, "https://api.github.com/teams/1234/members/benbaltertest").
      to_return(:status => 204)

      get "/"
      expect(last_response.status).to eql(200)
      expect(last_response.body).to match(/Submit an issue/)
    end
  end

  it "refuses to show the site with no auth strategy" do
    with_env "GITHUB_TEAM_ID", nil do
      with_env "GITHUB_ORG_ID", nil do
        with_env "GITHUB_TOKEN", nil do
          expect{get "/"}.to raise_error(/Must define GITHUB_TEAM_ID, GITHUB_ORG_ID, OR GITHUB_TOKEN/)
        end
      end
    end
  end

  it "allows the user to create an issue" do
    with_env "GITHUB_ORG_ID", "balter-test-org" do
      with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do

        stub_request(:get, "https://api.github.com/orgs/balter-test-org/members/benbaltertest").
        to_return(:status => 204)

        stub_request(:post, "https://api.github.com/repos/benbalter/test-repo-ignore-me/issues").
          with(:body => "{\"labels\":[],\"title\":\"title\",\"body\":\"* **Foo**: bar\"}").
          to_return(:status => 200, :body => '{"number": 1234}', :headers => { 'Content-Type' => 'application/json' })

        post "/", :title => "title", :foo => "bar"

        expect(last_response.status).to eql(200)
        expected = '<a href="http://github.com/benbalter/test-repo-ignore-me/issues/1234">benbalter/test-repo-ignore-me#1234</a>'
        expect(last_response.body).to match(expected)
      end
    end
  end
end

describe "logged out user" do
  include Rack::Test::Methods

  def app
    ProblemChild::App
  end

  it "asks the user to log in" do
    with_env "GITHUB_ORG_ID", "balter-test-org" do
      with_env "GITHUB_TOKEN", nil do
        get "/"
        expect(last_response.status).to eql(302)
        expect(last_response.headers['Location']).to match(%r{^https://github\.com/login/oauth/authorize})
      end
    end
  end

  it "allows anonymous users to see the form" do
    with_env "GITHUB_TOKEN", "1234" do
      get "/"
      expect(last_response.status).to eql(200)
      expect(last_response.body).to match(/Submit an issue/)
    end
  end

  it "allows anonymous submissions" do
    with_env "GITHUB_TOKEN", "1234" do
      with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do

        stub_request(:post, "https://api.github.com/repos/benbalter/test-repo-ignore-me/issues").
          with(:body => "{\"labels\":[],\"title\":\"title\",\"body\":\"* **Foo**: bar\"}").
          to_return(:status => 200, :body => '{"number": 1234}', :headers => { 'Content-Type' => 'application/json' })

        stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me").
          to_return(:status => 200, :body => '{"private": true}', :headers => { 'Content-Type' => 'application/json' })

        post "/", :title => "title", :foo => "bar"

        expect(last_response.status).to eql(200)
        expect(last_response.body).to match(/Your issue was successfully submitted\./)
      end
    end
  end

  it "supports submissions > 4k" do
    with_env "GITHUB_TOKEN", "1234" do
      with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
        long_string =  "0" * 5000

        stub_request(:post, "https://api.github.com/repos/benbalter/test-repo-ignore-me/issues").
          with(:body => "{\"labels\":[],\"title\":\"title\",\"body\":\"* **Foo**: #{long_string}\"}").
          to_return(:status => 200, :body => '{"number": 1234}', :headers => { 'Content-Type' => 'application/json' })

        stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me").
          to_return(:status => 200, :body => '{"private": true}', :headers => { 'Content-Type' => 'application/json' })

        post "/", :title => "title", :foo => long_string

        expect(last_response.status).to eql(200)
        expect(last_response.body).to match(/Your issue was successfully submitted\./)
      end
    end
  end
end
