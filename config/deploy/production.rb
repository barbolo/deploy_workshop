set :ec2_config, 'config/aws.yml'
set :ec2_region, %w{us-east-1}

ec2_role :application,
          user: 'ubuntu',
          ssh_options: {
            keys: [File.expand_path('~/.ssh/keys/deploy-workshop.pem', __FILE__)]
          }
