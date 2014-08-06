#!/bin/bash

# set the Rails environment to production
echo '
export RAILS_ENV="production"
' | sudo tee -a /etc/environment

# fix locales settings
echo '
LC_ALL="en_US.UTF-8"
' | sudo tee -a /etc/default/locale

# exit and create a new shell session
exit

# set up the timezone
sudo ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
sudo dpkg-reconfigure tzdata

# update the system's packages
sudo apt-get update
sudo apt-get -y upgrade

# install git
sudo apt-get -y install git-core

# install Ruby with RVM
curl -sSL https://get.rvm.io | sudo bash -s stable
sudo addgroup ubuntu rvm
sudo addgroup root rvm
source /etc/profile.d/rvm.sh
rvm install 2.1.2 # if it fails, exit and create a new shell session
rvm --default use 2.1.2

# install the application server: nginx + passenger
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
sudo apt-get install apt-transport-https ca-certificates
echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main" | sudo tee -a /etc/apt/sources.list.d/passenger.list
sudo chown root: /etc/apt/sources.list.d/passenger.list
sudo chmod 600 /etc/apt/sources.list.d/passenger.list
sudo apt-get update
sudo apt-get -y install nginx-extras passenger

# edit /etc/nginx/nginx.conf (nano, vi, ...)

# below the line which contains "http {", add:
more_set_headers "Server: server_name";
# (you can use any server name you would like to use)

# uncomment the line "# server_tokens off;"

# below the line which contains "Phusion Passenger config", add:
passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
passenger_ruby /usr/local/rvm/wrappers/default/ruby;

# remove the default nginx site
sudo rm /etc/nginx/sites-enabled/default

# restart nginx with the new configuration
sudo service nginx restart

# install monit, a tool that will monitor any service that should be running in the server
sudo apt-get -y install monit

echo '
check process nginx with pidfile /var/run/nginx.pid
  start program = "/etc/init.d/nginx start"
  stop program = "/etc/init.d/nginx stop"
  if failed port 80 protocol http request "/ping" then restart
  if 5 restarts with 5 cycles then timeout
' | sudo tee -a /etc/monit/conf.d/nginx.monitrc

sudo service monit restart

# nokogiri dependencies
sudo apt-get -y install libxslt1-dev libxml2-dev

# rmagick/paperclip dependencies
sudo apt-get -y install imagemagick libmagickwand-dev

# mysql2 dependencies
sudo apt-get -y install mysql-client libmysqlclient-dev

# "rake assets:precompile" dependencies
sudo apt-get -y install nodejs

# prepare the server for initialization with Auto Scaling
gem install aws-sdk -v 1.40.2 --no-ri --no-rdoc
gem install logger -v 1.2.8 --no-ri --no-rdoc

# copy the content from initialize_server.rb
# (update the constants ACCESS_KEY_ID and SECRET_ACCESS_KEY)
nano ~/initialize_server.rb

chmod u+x ~/initialize_server.rb
