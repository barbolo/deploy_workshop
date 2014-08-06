# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'deploy_workshop'
set :repo_url, 'https://github.com/barbolo/deploy_workshop.git'
set :scm, :git
set :deploy_to, '/home/ubuntu/git/deploy_workshop'
set :linked_files, %w{config/initializers/set_env_variables.rb}
set :linked_dirs, %w{log tmp}
set :keep_releases, 5
set :rvm_type, :system
set :bundle_gemfile, -> { release_path.join('Gemfile') }

# Remote caching will keep a local git repository on the server you're
# deploying to and simply run a fetch from that rather than an entire clone.
set :deploy_via, :remote_cache

# Capistrano shouldn't mess up with assets. So we set the following to false.
set :normalize_asset_timestamps, false

# Define some tasks
namespace :deploy do
  task :stop_monit do
    on roles(:api_rails) do
      sudo "service monit stop"
    end
  end
  task :start_monit do
    on roles(:api_rails) do
      sudo "service monit start"
    end
  end
  task :restart do
    on roles(:api_rails), in: :sequence, wait: 5 do
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end
end

# Schedule some tasks execution

# Stop monit before deploying
after 'deploy:started', 'deploy:stop_monit'

# Clean up old releases on each deploy
before 'deploy:finished', 'deploy:cleanup'

# Restart the application
after 'deploy:finished', 'deploy:restart'

# Restart monit after deploying
after 'deploy:finished', 'deploy:start_monit'
