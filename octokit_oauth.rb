require 'octokit'
require 'sinatra'

# tmp CLIENT_ID
set :port, 3311
use Rack::Session::Cookie, :secret => rand.to_s()
set :protection, :frame_options => "ALLOW-FROM *"

#REMOVE_ME
DEBUG = true
begin
  GITHUB_HOSTNAME = ENV.fetch("GITHUB_HOSTNAME")
  GITHUB_CLIENT_ID = ENV.fetch("GITHUB_CLIENT_ID")
  GITHUB_CLIENT_SECRET = ENV.fetch("GITHUB_CLIENT_SECRET")
rescue KeyError
  $stderr.puts "To run this script, please set the following environment variables:"
  $stderr.puts "- GITHUB_HOSTNAME: Fully qualified domain name to GitHub Enterprise"
  $stderr.puts "- GITHUB_CLIENT_ID: GitHub Developer Application Client ID"
  $stderr.puts "- GITHUB_CLIENT_SECRET: GitHub Developer Application Client Secret"
  exit 1
end

# Assuming GitHub Enterprise Endpoint 
Octokit.configure do |c|
  c.api_endpoint = "#{GITHUB_HOSTNAME}/api/v3/"
  c.web_endpoint = GITHUB_HOSTNAME
  c.auto_paginate = true
end

client = Octokit::Client.new
if DEBUG
  client.connection_options[:ssl] = { :verify => false }
end

get '/callback' do 
  session_code = params[:code]
  result = Octokit.exchange_code_for_token(session_code, GITHUB_CLIENT_ID, GITHUB_CLIENT_SECRET)
  session[:access_token] = result[:access_token]
  redirect to('/')
end

# Returns true if the user completed OAuth2 handshake and has a token
def authenticated?
  !session[:access_token].nil?
end

# Returns whether the user selected a repository to map to this JIRA project
def set_repo?
  !session[:repo_name].nil?
end

# Returns whether a branch for this issue already exists 
def branch_exists?
  !session[:branch_name].nil?
end

# Store which Repository the user selected 
get '/add_repo' do
  if !authenticated?
    redirect to('/')
  end

  input_repo = params[:repo_name]
  session[:repo_name] = input_repo if session[:name_list].include? input_repo.to_s  
  redirect to('/')
end

# Public route to install Add-on from Atlassian
get '/atlassian-connect.json' do
  content_type :json
  File.read(File.join('public', 'atlassian-connect.json'))
end

# Entry point for JIRA Add-on.
# JIRA passes in a number of URL parameters https://goo.gl/zyGLiF
get '/main_entry' do
  $fqdn = params[:xdm_e]
  redirect to('/')
end

get '/hello-you.html' do
  # Assume JIRA project doesn't contain '/'
  jira_issue = request.referrer.split('/').last
  session[:jira_issue] = jira_issue
  $fqdn = params[:xdm_e]
  redirect to('/')
end

# Main application logic
get '/' do
  # Ensure user is authenticated with OAuth token
  if !authenticated?
    @url = client.authorize_url(GITHUB_CLIENT_ID, :scope => 'repo')
    return erb :authorize
  else
    # Switch to end-user's token for GitHub API calls
    client = Octokit::Client.new(:access_token => session[:access_token] )
    client.connection_options[:ssl] = { :verify => false }
        
    if !set_repo?
      @name_list = [] 
      # Get all repositories a user has write access to
      client.repos.each do |repo|
        @name_list.push(repo[:full_name]) if repo[:permissions][:admin] || repo[:permissions][:push] 
      end
      session[:name_list] = @name_list
      # Show end-user a list of all repositories they can create a branch in
      return erb :show_repos
    else
      if branch_exists?
        return erb :link_to_branch
      end      
      @repo_name = session[:repo_name]
      return erb :create_branch
    end
  end
end

# Create a branch for the selected repository if it doesn't already exist.
get '/create_branch' do
  if !authenticated? || !set_repo?
    redirect to('/')
  end
  client = Octokit::Client.new(:access_token => session[:access_token] )
  client.connection_options[:ssl] = { :verify => false }

  repo_name = session[:repo_name]
  branch_name = session[:jira_issue]
  begin
    # Does this branch exist
    sha = client.ref(repo_name, "heads/#{branch_name}")
    session[:branch_name] = branch_name
  rescue Octokit::NotFound
    # Create branch
    sha = client.ref(repo_name, "heads/master")[:object][:sha]
    ref = client.create_ref(repo_name, "heads/#{branch_name}", sha.to_s)
    session[:branch_name] = branch_name
  end
  redirect to('/')
end

# Clear all session information
get '/logout' do
  session[:access_token] = nil
  session[:repo_name] = nil
  session[:name_list] = nil
  session[:branch_name] = nil
  redirect to('/')
end
