require 'bundler/capistrano' # enable bundler stuff!

load 'deploy/assets'

# rvm stuff
require "rvm/capistrano"
set :rvm_ruby_string, '1.9.3-p194'        # Or whatever env you want it to run in.
###

set(:deploy_to) { File.join("", "home", user, "sites", application) }
set :config_files, %w()
default_run_options[:pty] = true

ssh_options[:keys] = [File.join(ENV["HOME"], ".ssh", "id_rsa")]

server "digitalsocial.eu", :app, :web, :db, :primary => true

set :application, "linkeddevelopment_api"
set :branch, "master"
set :rails_env, "production"

set :repository,  "git@github.com:Swirrl/linked_development_api.git"
set :scm, "git"
set :ssh_options, {:forward_agent => true, :keys => "~/.ssh/id_rsa" }
set :user, "rails"
set :runner, "rails"
set :admin_runner, "rails"
set :use_sudo, false

set :deploy_via, :remote_cache

after "deploy:setup",
  "deploy:upload_app_config"

after "deploy:finalize_update",
  "deploy:symlink_app_config"

namespace :deploy do

  desc <<-DESC
    overriding deploy:cold task to not migrate...
  DESC
  task :cold do
    update
    start
  end

  desc <<-DESC
    overriding start to just call restart
  DESC
  task :start do
    restart
  end

  desc <<-DESC
    overriding stop to do nothing - you cant stop a passenger app!
  DESC
  task :stop do
  end

  desc "Copy local config files from app's config folder to shared_path."
  task :upload_app_config do
    config_files.each { |filename| put(File.read("config/#{filename}"), "#{shared_path}/#{filename}", :mode => 0640) }
  end

  desc "Symlink the application's config files specified in :config_files to the latest release"
  task :symlink_app_config do
    config_files.each { |filename| run "ln -nfs #{shared_path}/#{filename} #{latest_release}/config/#{filename}" }
  end

  desc <<-DESC
  overriding start to just touch the restart txt
  DESC
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

require './config/boot'
