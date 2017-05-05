# atlassian-github-addon

Install a push

### Configuration

* Install Ruby, [Octokit](https://github.com/octokit/octokit.rb)
* [Register an OAuth application](https://developer.github.com/guides/basics-of-authentication/#registering-your-app) in GitHub Enterprise
* An Atlassian account using JIRA and [development mode](https://developer.atlassian.com/static/connect/docs/beta/guides/development-setup.html#enable-development-mode) enabled

### Usage

1. Clone source and run `bundler install` to install Ruby dependencies
1. Customize [`atlassian_connect.json`](https://github.com/osowskit/atlassian-github-addon/blob/master/atlassian_connect.json) so `baseUrl` points to the public IP of your server 
1. Run `ruby octokit_oauth.rb` on a server with a public IP 
1. Navigate to Atlassian and install the [add-on](https://developer.atlassian.com/static/connect/docs/beta/guides/development-setup.html#install-addon)
1. Navigate to a JIRA ticket and follow the steps under **GitHub Development** to complete the [authorization to GitHub Enterprise](https://developer.github.com/v3/oauth/#web-application-flow)
