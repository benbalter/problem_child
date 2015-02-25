require "spec_helper"

describe "ProblemChild::Helpers" do

  class TestHelper
    include ProblemChild::Helpers
    extend  ProblemChild::RedisHelper

    attr_accessor :session, :params

    def initialize(path=nil)
      @path = path
      TestHelper.init_redis!
    end

    def request
      Rack::Request.new("PATH_INFO" => @path)
    end
  end

  before(:each) do
   @helper = TestHelper.new
   @helper.session = {}
   @helper.params = {}
  end

  it "knows the github repo" do
    with_env "GITHUB_REPO", "foo/bar" do
      expect(@helper.repo).to eql("foo/bar")
    end
  end

  it "knows to allow anonymous submisssions when a token is passed" do
    with_env "GITHUB_TOKEN", "asdf" do
      expect(@helper.anonymous_submissions?).to be(true)
    end
  end

  it "knows not to allow anonymous submisssions when no token is passed" do
    with_env "GITHUB_TOKEN", "" do
      expect(@helper.anonymous_submissions?).to be(false)
    end

    with_env "GITHUB_TOKEN", nil do
      expect(@helper.anonymous_submissions?).to be(false)
    end
  end

  it "uses a token if passed" do
    with_env "GITHUB_TOKEN", "asdf" do
      expect(@helper.token).to eql("asdf")
    end
  end

  it "inits the octokit client" do
    with_env "GITHUB_TOKEN", "asdf" do
      expect(@helper.client.class).to eql(Octokit::Client)
      expect(@helper.client.access_token).to eql("asdf")
    end
  end

  it "grabs the form data from redis" do
    expected = {"title" => "title", "foo" => "bar"}
    @helper.params = expected
    @helper.cache_data
    @helper.params = nil
    expect(@helper.form_data).to eql(expected)
  end

  it "grabs the form data when posted" do
    expected = {"title" => "title", "foo" => "bar"}
    @helper.params = expected
    expect(@helper.form_data).to eql(expected)
  end

  it "builds the issue body" do
    expected = {"title" => "title", "foo" => "bar"}
    @helper.params = expected
    expect(@helper.issue_body).to eql("* **Foo**: bar")
  end

  it "submits the issue" do
    expected = {"title" => "title", "foo" => "bar"}
    @helper.params = expected
    with_env "GITHUB_TOKEN", "1234" do
      with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do

        stub = stub_request(:post, "https://api.github.com/repos/benbalter/test-repo-ignore-me/issues").
          with(:body => "{\"labels\":[],\"title\":\"title\",\"body\":\"* **Foo**: bar\"}").
          to_return(:status => 200)

        @helper.create_issue
        expect(stub).to have_been_requested
      end
    end
  end

  it "knows the session id" do
    @helper.session["session_id"] = "1234"
    expect(@helper.session_id).to eql("1234")
  end

  it "can access redis" do
    expect(@helper.redis.class).to eql(Redis)
  end

  it "caches the data" do
    expected = {"title" => "title", "foo" => "bar"}
    @helper.params = expected
    @helper.cache_data
    expect(@helper.redis.get(@helper.session_id)).to eql(expected.to_json)
  end

  it "retrieves cached data" do
    expected = {"title" => "title", "foo" => "bar"}
    @helper.params = expected
    @helper.cache_data
    expect(@helper.cached_data).to eql(expected)
  end
end
