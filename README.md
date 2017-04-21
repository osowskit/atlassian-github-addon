# atlassian-github-addon


### Configuration

* Install Ruby, [Octokit](https://github.com/octokit/octokit.rb)
* Set up an OAuth application in GitHub Enterprise
* An Atlassian account using JIRA and [development mode](https://developer.atlassian.com/static/connect/docs/beta/guides/development-setup.html#enable-development-mode) enabled

### Usage

1. Download source and install Ruby dependencies
1. Customize [`atlassian_connect.json`](https://github.com/osowskit/atlassian-github-addon/blob/master/atlassian_connect.json) so `baseUrl` points to the public IP of your server 
1. Run `ruby octokit_oauth.rb` on a server with a public IP 
1. Navigate to Atlassian and install the [add-on](https://developer.atlassian.com/static/connect/docs/beta/guides/development-setup.html#install-addon)
1. Navigate to a JIRA ticket and follow the steps under **GitHub Development** to complete the authorization to GitHub Enterprise
