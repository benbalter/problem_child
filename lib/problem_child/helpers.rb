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

    def issue_body
      form_data.reject { |key, value| key == "title" || value.empty? }.map { |key,value| "* **#{key.humanize}**: #{value}"}.join("\n")
    end

    # abstraction to allow cached form data to be used in place of default params
    def form_data
      session["form_data"].nil? ? params : JSON.parse(session["form_data"])
    end

    def create_issue
      issue = client.create_issue(repo, form_data["title"], issue_body)
      issue["number"] if issue
    end

    def repo_access?
      return true unless anonymous_submissions?
      !client.repository(repo)["private"]
    rescue
      false
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
