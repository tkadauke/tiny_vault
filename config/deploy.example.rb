require 'bundler/capistrano'

set :application, "tiny_vault"
set :repository,  "git://github.com/tkadauke/tiny_vault.git"
set :user, "Insert your user name here"

set :deploy_to, "/var/www/apps/#{application}"
set :deploy_via, :remote_cache

set :scm, :git

role :app, "Insert your server name here"
role :web, "Insert your server name here"
role :db,  "Insert your server name here", :primary => true

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end

  desc "Symlink shared configs and folders on each release."
  task :symlink_shared do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end
end

after 'deploy:update_code', 'deploy:symlink_shared'
