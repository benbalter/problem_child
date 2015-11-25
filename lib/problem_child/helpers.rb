module ProblemChild
  module Helpers

    def repo
      ENV["GITHUB_REPO"]
    end

    def anonymous_submissions?
      !!(ENV["GITHUB_TOKEN"] && !ENV["GITHUB_TOKEN"].to_s.empty?)
    end

    def token
      if anonymous_submissions?
        ENV["GITHUB_TOKEN"]
      elsif !github_user.nil?
        github_user.token
      end
    end

    def client
      @client ||= Octokit::Client.new :access_token => token
    end

    def render_template(template, locals={})
      halt erb template, :layout => :layout, :locals => locals.merge({ :template => template })
    end

    def issue_title
      form_data["title"]
    end

    def issue_body
      form_data.reject { |key, value|
        key == "title" || value.empty? || key == "labels" || value.is_a?(Hash)
      }.except( "g-recaptcha-response" ).map { |key, value|
        "* **#{key.humanize}**: #{value}"
      }.join("\n")
    end

    # abstraction to allow cached form data to be used in place of default params
    def form_data
      session["form_data"].nil? ? params : JSON.parse(session["form_data"])
    end

    def labels
      form_data["labels"].join(",") if form_data["labels"]
    end

    def uploads
      form_data.select do |key, value|
        value.is_a?(Hash) && ( value.has_key?("filename") || value.has_key?(:filename) )
      end
    end

    def create_issue
      issue = client.create_issue(repo, form_data["title"], issue_body, :labels => labels)
      issue["number"] if issue
    end

    # Returns array of Octokit branch objects
    def branches
      client.branches(repo)
    end

    # Head SHA of default branch, used for creating new branches
    def base_sha
      default_branch = client.repo(repo)[:default_branch]
      branches.find { |branch| branch[:name] == default_branch }[:commit][:sha]
    end

    def branch_exists?(branch)
      branches.any? { |b| b.name == branch }
    end

    # Name of branch to submit pull request from
    # Starts with patch-1 and keeps going until it finds one not taken
    def patch_branch
      num = 1
      branch_name = form_data["title"].parameterize
      return branch_name unless branch_exists?(branch_name)
      branch = "#{branch_name}-#{num}"
      while branch_exists?(branch) do
        num = num + 1
        branch = "#{branch_name}-#{num}"
      end
      branch
    end

    # Create a branch with the given name, based off of HEAD of the defautl branch
    def create_branch(branch)
      client.create_ref repo, "heads/#{branch}", base_sha
    end

    # Create a pull request with the form contents
    def create_pull_request
      unless uploads.empty?
        branch = patch_branch
        create_branch(branch)
        uploads.each do |key, upload|
          client.create_contents(
            repo,
            upload["filename"],
            "Create #{upload["filename"]}",
            session["file_#{key}"],
            :branch => branch
          )
          session["file_#{key}"] = nil
        end
      end
      pr = client.create_pull_request(repo, "master", branch, form_data["title"], issue_body, :labels => labels)
      pr["number"] if pr
    end

    def repo_access?
      return true unless anonymous_submissions?
      !client.repository(repo)["private"]
    rescue
      false
    end

    def cache_form_data
      uploads.each do |key, upload|
        session["file_#{key}"] = File.open(upload[:tempfile]).read
      end
      session[:form_data] = params.to_json
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
  end
end
