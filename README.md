# Problem Child

Allows authenticated or anonymous users to fill out a standard web form to create GitHub issues.

[![Build Status](https://travis-ci.org/benbalter/problem_child.svg)](https://travis-ci.org/benbalter/problem_child)

## How it works

1. You create a standard HTML form, defining what fields you'd like a given authenticated or anonymous user to fill out
2. They go to a hosted URL and fill out the form
3. The fields are converted to markdown bullets and inserted into the body of a new issue created against the GitHub repo you specify

## Usage

1. Create a `Gemfile` and add `gem "problem_child"`
2. Create a `config.ru` file and add the following:
  ```ruby
  require "problem_child"
  run ProblemChild::App
  ```
3. Follow the configuration options below

## Requirements

You'll need to have [Redis](http://redis.io/) running.

On OS X, run `brew install redis` to install, followed by `redis-server` to run the redis server.

On Heroku you'll want to run `heroku addons:create heroku-redis:hobby-dev` to add a free Redis instance to your app.

## Configuring

You must set the following as environmental variables:

* `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` - Created via [github.com/settings/applications/new](https://github.com/settings/applications/new)
* `GITHUB_REPO` - the repo to open the issue against in the form of `owner/repo`

You must also set **one** of the following:

* `GITHUB_TOKEN` - A personal access token for a bot account with the ability to create an issue in the `GITHUB_REPO` if you would like all submissions to be anonymous
* `GITHUB_ORG_ID` - The GitHub Org ID e.g, `@whitehouse` if you'd like all users to authenticate against a GitHub Org prior to being presented the form
* `GITHUB_TEAM_ID` - The numeric Team ID (e.g., 1234) if you'd like all users to authenticate against a GitHub Team prior to being presented the form

*Pro-tip*: When developing locally, you can add these values to a `.env` file in the project root, and they will be automatically read in on load

## Customizing

By default, Problem Child will prompt the user with a simple form that contains only the title and body. If you'd like to customize the form, you must do the following:

1. Create a new folder called `views`
2. Create a `layout.erb` and `form.erb`
3. Customize both the layout and form as a standard HTML form. Check out [these examples](lib/problem_child/views) to get started.
4. Add the following (middle) line to your `config.ru` file:

```ruby
require "problem_child"
ProblemChild.views_dir = "/path/to/your/views/directory"
run ProblemChild::App
```

*Pro-tip*: You can use any standard HTML form fields, but be sure to name one field `title`, which will become the issue title.

*Pro-tip II*: Problem child can set labels. You can do this either as a hidden field:

```html
<input type="hidden" name="labels[]" value="bug" />
```

or as a checkbox:

```html
<input type="checkbox" name="labels[]" value="bug" />
<input type="checkbox" name="labels[]" value="suggestion" />
```

## Creating pull requests

Problem child can also be used to create pull requests. Simply add one or more file inputs to your form. The uploaded files will be committed to a newly created feature branch, and a pull request will be created against the repo's primary branch with the rest of the form content. You'll also want to change the form type to `enctype="multipart/form-data"`.

```html
<form method="post" enctype="multipart/form-data">
  <input type="file" name="file" />
  <input type="submit" />
</form>
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/problem_child/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
