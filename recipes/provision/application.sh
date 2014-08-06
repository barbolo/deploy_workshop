#!/bin/bash

#
# ATTENTION! CHANGE THE CONSTANTS BELOW!
#
GIT_CLONE_URL="https://github.com/barbolo/deploy_workshop.git"

# create capistrano folders
mkdir -p ~/git/deploy_workshop/releases
mkdir -p ~/git/deploy_workshop/shared/log
mkdir -p ~/git/deploy_workshop/shared/tmp
mkdir -p ~/git/deploy_workshop/shared/tmp/pids
mkdir -p ~/git/deploy_workshop/shared/config/initializers/

# Create a file that will load environment variables into the Rails app.
# Copy the contents from set_env_variables.rb
nano ~/git/deploy_workshop/shared/config/initializers/set_env_variables.rb

# Clone project and set up capistrano
CAPISTRANO_TIMESTAMP="20140101000000" # choose an old datetime
git clone $GIT_CLONE_URL ~/git/deploy_workshop/releases/$CAPISTRANO_TIMESTAMP

ln -s /home/ubuntu/git/deploy_workshop/releases/$CAPISTRANO_TIMESTAMP /home/ubuntu/git/deploy_workshop/current

rm -rf /home/ubuntu/git/deploy_workshop/releases/$CAPISTRANO_TIMESTAMP/log
ln -s /home/ubuntu/git/deploy_workshop/shared/log /home/ubuntu/git/deploy_workshop/releases/$CAPISTRANO_TIMESTAMP/log

rm -rf /home/ubuntu/git/deploy_workshop/releases/$CAPISTRANO_TIMESTAMP/tmp
ln -s /home/ubuntu/git/deploy_workshop/shared/tmp /home/ubuntu/git/deploy_workshop/releases/$CAPISTRANO_TIMESTAMP/tmp

rm /home/ubuntu/git/deploy_workshop/current/config/initializers/set_env_variables.rb
ln -s /home/ubuntu/git/deploy_workshop/shared/config/initializers/set_env_variables.rb /home/ubuntu/git/deploy_workshop/current/config/initializers/

git clone --mirror $GIT_CLONE_URL /home/ubuntu/git/deploy_workshop/repo

touch /home/ubuntu/git/deploy_workshop/current/tmp/restart.txt

# Setup the Rails project
cd ~/git/deploy_workshop/current

bundle install --path ~/git/deploy_workshop/shared/bundle
bundle exec rake db:create # execute only when you are creating the application
bundle exec rake db:migrate
bundle exec rake db:seed

sudo nano /etc/nginx/sites-available/application

server {
  listen 80;
  passenger_enabled on;
  passenger_app_env production;
  root /home/ubuntu/git/deploy_workshop/current/public;
  access_log /home/ubuntu/git/deploy_workshop/current/log/access.log;
  error_log /home/ubuntu/git/deploy_workshop/current/log/error.log;
  location ~* ^/assets/ {
    # Per RFC2616 - 1 year maximum expiry
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html
    expires 1y;
    add_header Cache-Control public;

    # Some browsers still send conditional-GET requests if there's a
    # Last-Modified header or an ETag header even if they haven't
    # reached the expiry date sent in the Expires header.
    add_header Last-Modified "";
    add_header ETag "";
    break;
  }
}

sudo ln -s /etc/nginx/sites-available/application /etc/nginx/sites-enabled/application

sudo service nginx restart
