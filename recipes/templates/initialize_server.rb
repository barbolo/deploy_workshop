#!/usr/bin/env ruby

require 'aws-sdk'
require 'logger'

ACCESS_KEY_ID = 'PUT_YOUR_ACCESS_KEY_ID_HERE'
SECRET_ACCESS_KEY = 'PUT_YOUR_SECRET_ACCESS_KEY_HERE'

started_at = Time.now
log = Logger.new('/home/ubuntu/init.log')
log.info '[init] Let\'s start this server!'

instance_id = `/usr/bin/ec2metadata --instance-id`.strip
public_dns = `/usr/bin/ec2metadata --public-hostname`.strip
region = `/usr/bin/ec2metadata --availability-zone`.strip.gsub(/[a-z]\Z/, '')
project_dir = '/home/ubuntu/git/deploy_workshop'
success = true

begin

  # Stop Monit
  log.info '[init] Stopping monit...'
  log.info `sudo service monit stop`
  raise if $?.to_i != 0
  log.info 'OK'

  # Stop Nginx
  log.info '[init] Stopping Nginx...'
  log.info `sudo service nginx stop`
  raise if $?.to_i != 0
  log.info 'OK'

  # Pull repo
  log.info '[init] Pulling repo...'
  log.info `sudo -i -u ubuntu sh -c "cd #{project_dir}/current && git pull origin release"`
  raise if $?.to_i != 0
  log.info 'OK'

  # Bundle install
  log.info '[init] Bundle install...'
  log.info `sudo -i -u ubuntu sh -c "cd #{project_dir}/current && bundle install --path #{project_dir}/shared/bundle"`
  raise if $?.to_i != 0
  log.info 'OK'

  tries = 0
  begin
    # Start nginx
    log.info '[init] Starting nginx...'
    log.info `sudo service nginx start`
    raise if $?.to_i != 0
    log.info 'OK'
  rescue Exception => exc
    if tries < 4
      log.error exc.message
      tries += 1
      retry
    else
      raise 'Failed to start nginx'
    end
  end

  # Start Monit
  log.info '[init] Starting monit...'
  log.info `sudo service monit start`
  raise if $?.to_i != 0
  log.info 'OK'

  # Tag instance
  log.info '[init] Tagging instance...'
  AWS.config(
    access_key_id: ACCESS_KEY_ID,
    secret_access_key: SECRET_ACCESS_KEY,
    region: region
  )
  ec2 = AWS.ec2
  ec2.instances[instance_id].add_tag('Name', :value => "DEPLOY WORKSHOP (#{Time.now.strftime("%Y-%m-%d %H:%M")})")
  ec2.instances[instance_id].add_tag('Project', :value => 'deploy_workshop')
  ec2.instances[instance_id].add_tag('Roles', :value => 'application')
  ec2.instances[instance_id].add_tag('Stages', :value => 'production')
  log.info 'OK'

rescue Exception => exc
  success = false
  log.error exc
  log.error exc.backtrace
end
