require "spec_helper"

describe "ProblemChild::Helpers" do

  class TestHelper
    include ProblemChild::Helpers

    attr_accessor :session, :params

    def initialize(path=nil)
      @path = path
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

    with_env "GITHUB_TOKEN", "" do
      expect(@helper.anonymous_submissions?).to be(false)
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

  it "caches the form data" do
    @helper.params = {"title" => "title", "foo" => "bar"}
    @helper.cache_form_data
    expect(@helper.form_data["foo"]).to eql("bar")
  end

  it "grabs the form data from the session" do
    expected = {"title" => "title", "foo" => "bar"}
    @helper.session["form_data"] = expected.to_json
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
    @helper.params = {"title" => "title", "foo" => "bar", "labels" => ["foo", "bar"]}
    with_env "GITHUB_TOKEN", "1234" do
      with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do

        stub = stub_request(:post, "https://api.github.com/repos/benbalter/test-repo-ignore-me/issues").
          with(:body => "{\"labels\":[\"foo\",\"bar\"],\"title\":\"title\",\"body\":\"* **Foo**: bar\"}").
          to_return(:status => 200, :body => '{"number": 1234}', :headers => { 'Content-Type' => 'application/json' })

        expect(@helper.create_issue).to eql(1234)
        expect(stub).to have_been_requested
      end
    end
  end

  it "knows auth'd users can access a repo" do
    stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me").
      to_return(:status => 200, :body => '{"private": true}', :headers => { 'Content-Type' => 'application/json' })

    with_env "GITHUB_TOKEN", nil do
      with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
        expect(@helper.repo_access?).to eql(true)
      end
    end
  end

  it "knows anonymous users can access public repos" do
    stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me").
      to_return(:status => 200, :body => '{"private": false}', :headers => { 'Content-Type' => 'application/json' })

    with_env "GITHUB_TOKEN", "1234" do
      with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
        expect(@helper.repo_access?).to eql(true)
      end
    end
  end

  it "knows anonymous users can't access private repos" do
    stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me").
      to_return(:status => 200, :body => '{"private": true}', :headers => { 'Content-Type' => 'application/json' })

    with_env "GITHUB_TOKEN", "1234" do
      with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
        expect(@helper.repo_access?).to eql(false)
      end
    end
  end

  it "knows the labels" do
    @helper.params["labels"] = ["foo", "bar"]
    expect(@helper.labels).to eql("foo,bar")
  end

  context "uploads" do
    it "can identify uploads" do
      @helper.params = {"title" => "title", "file" => { :filename => "foo.md"} }
      expect(@helper.uploads.first[0]).to eql("file")
    end

    it "fetches the branches" do
      stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me/branches").
         to_return(:status => 200, :body => [{ :name => "master", :commit => { :sha => "1" } }])

      with_env "GITHUB_TOKEN", "1234" do
        with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
          expect(@helper.branches[0][:name]).to eql("master")
        end
      end
    end

    it "fetches the base sha" do
      stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me/branches").
         to_return(:status => 200, :body => [{ :name => "master", :commit => { :sha => "123" } }])

         stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me").
            to_return(:status => 200, :body => {:default_branch => "master"}.to_json,
            :headers => { "Content-Type" => "application/json" })

      with_env "GITHUB_TOKEN", "1234" do
        with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
          expect(@helper.base_sha).to eql("123")
        end
      end
    end

    it "knows if a branch exists" do
      stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me/branches").
         to_return(:status => 200, :body => [{ :name => "master", :commit => { :sha => "123" } }].to_json,
         :headers => { "Content-Type" => "application/json" })

      with_env "GITHUB_TOKEN", "1234" do
        with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
          expect(@helper.branch_exists?("master")).to eql(true)
          expect(@helper.branch_exists?("master2")).to eql(false)
        end
      end
    end

    it "creates the branch name" do
      stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me/branches").
         to_return(:status => 200, :body => [{ :name => "master", :commit => { :sha => "123" } }].to_json,
         :headers => { "Content-Type" => "application/json" })

      with_env "GITHUB_TOKEN", "1234" do
        with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
          @helper.params = {"title" => "My title" }
          expect(@helper.patch_branch).to eql("my-title")

          @helper.params = {"title" => "master" }
          expect(@helper.patch_branch).to eql("master-1")
        end
      end
    end

    it "creates a branch" do
      stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me").
         to_return(:status => 200, :body => {:default_branch => "master"}.to_json,
         :headers => { "Content-Type" => "application/json" })

       stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me/branches").
          to_return(:status => 200, :body => [{ :name => "master", :commit => { :sha => "123" } }].to_json,
          :headers => { "Content-Type" => "application/json" })

      stub = stub_request(:post, "https://api.github.com/repos/benbalter/test-repo-ignore-me/git/refs").
         with(:body => "{\"ref\":\"refs/heads/my-branch\",\"sha\":\"123\"}")

      with_env "GITHUB_TOKEN", "1234" do
        with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
          @helper.create_branch("my-branch")
          expect(stub).to have_been_requested
        end
      end
    end

    it "caches uploads" do
      path = File.expand_path "./fixtures/file.txt", File.dirname(__FILE__)
      @helper.params = { "title" => "title", "some_file" => { :filename => "file.txt", :tempfile => path } }
      @helper.cache_form_data
      expect(@helper.session["file_some_file"]).to eql("FOO\n")
    end

    it "creates the pull request" do
      stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me").
         to_return(:status => 200, :body => {:default_branch => "master"}.to_json,
         :headers => { "Content-Type" => "application/json" })

       stub_request(:get, "https://api.github.com/repos/benbalter/test-repo-ignore-me/branches").
          to_return(:status => 200, :body => [{ :name => "master", :commit => { :sha => "123" } }].to_json,
          :headers => { "Content-Type" => "application/json" })

      stub_request(:post, "https://api.github.com/repos/benbalter/test-repo-ignore-me/git/refs").
         with(:body => "{\"ref\":\"refs/heads/title\",\"sha\":\"123\"}").
         to_return(:status => 200)

      push = stub_request(:put, "https://api.github.com/repos/benbalter/test-repo-ignore-me/contents/").
         with(:body => "{\"branch\":\"title\",\"content\":\"Rk9PCg==\",\"message\":\"Create \"}")

      pr = stub_request(:post, "https://api.github.com/repos/benbalter/test-repo-ignore-me/pulls").
         with(:body => "{\"labels\":null,\"base\":\"master\",\"head\":\"title\",\"title\":\"title\",\"body\":\"* **Foo**: bar\"}")

      with_env "GITHUB_TOKEN", "1234" do
        with_env "GITHUB_REPO", "benbalter/test-repo-ignore-me" do
          path = File.expand_path "./fixtures/file.txt", File.dirname(__FILE__)
          @helper.params = { "title" => "title", "some_file" => { :filename => "file.txt", :tempfile => path }, "foo" => "bar" }
          @helper.cache_form_data
          @helper.create_pull_request
          expect(push).to have_been_requested
          expect(pr).to have_been_requested
        end
      end
    end
  end
end
