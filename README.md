# Who said Puppet was hard?

Example code for provisioning a server in 5' with Puppet in standalone
mode so that you can install a Rails app with your standard Capistrano
workflow. This sets up a `deploy` user with proper authorized keys, ntp
configuration, rbenv, Ruby 1.9.3, Passenger 3.x, and Apache + vhost on
port 80.

Here are the commands you would have to launch if you wanted to install
the app after having done the setup that will be described in the next
sections:

    git clone https://github.com/crohr/who-said-puppet-was-hard
    cd who-said-puppet-was-hard
    bundle install --binstubs
    ./bin/librarian-puppet install
    REMOTE_USER=ubuntu HOSTS=server.com ./bin/cap provision
    HOSTS=server.com ./bin/cap deploy:setup deploy

## Setup

    rails new who-said-puppet-was-hard -T --skip-bundle
    cd who-said-puppet-was-hard/

    echo 'gem "librarian-puppet", "0.9.3", :group => :development' >> Gemfile
    echo 'gem "capistrano", :group => :development' >> Gemfile

    bundle install --binstubs
    ./bin/capify .
    ./bin/librarian-puppet init

## Puppetfile

See [`Puppetfile`](https://github.com/crohr/who-said-puppet-was-hard/blob/master/Puppetfile). 
Then install the modules with:

    ./bin/librarian-puppet install

## Declare what you need on your server

See [`config/site.pp`](https://github.com/crohr/who-said-puppet-was-hard/blob/master/config/site.pp).

## Use Capistrano to bootstrap the provisioning process

Add this at the end of your [`config/deploy.rb`](https://github.com/crohr/who-said-puppet-was-hard/blob/master/config/deploy.rb) file:

      set :puppet_dir, "/tmp/puppet"
      set :puppet_cmd, "/var/lib/gems/1.8/bin/puppet"

      desc "Install and configure the puppet recipes on a remote machine."
      task :provision do
        system "rm -f modules.tar.gz && tar czf modules.tar.gz modules"
        run "rm -rf #{puppet_dir} && mkdir -p #{puppet_dir}"

        upload "modules.tar.gz", puppet_dir, :force => true, :via => :scp
        upload "./config/site.pp", puppet_dir, :force => true, :via => :scp

        run "cd #{puppet_dir} && tar xzf modules.tar.gz && \
          #{sudo} apt-get update && #{sudo} apt-get install ruby1.8 rubygems1.8 libopenssl-ruby1.8 -y && \
          ( [ -f #{puppet_cmd} ] || #{sudo} gem install puppet --version 2.6.11 --no-ri --no-rdoc ) && \
          #{sudo} #{puppet_cmd} #{puppet_dir}/site.pp --modulepath #{puppet_dir}/modules/"
      end

## Profit

Provision on a fresh instance (for example, use one of the [Ubuntu Cloud images](http://uec-images.ubuntu.com/releases/10.04/release/)):

    REMOTE_USER=ubuntu HOSTS=ec2-46-137-51-216.eu-west-1.compute.amazonaws.com ./bin/cap provision

Deploy:

    HOSTS=ec2-46-137-51-216.eu-west-1.compute.amazonaws.com ./bin/cap deploy:setup deploy

Done:

    $ curl ubuntu-ec2-instance-somewhere:80
    <!DOCTYPE html>
    <html>
    <head>
      <title>WhoSaidPuppetWasHard</title>
      <link href="/assets/application-7270767b2a9e9fff880aa5de378ca791.css" media="all" rel="stylesheet" type="text/css" />
      <script src="/assets/application-118bda7be2ac41c773269436ace3cc1e.js" type="text/javascript"></script>
      <meta content="authenticity_token" name="csrf-param" />
    <meta content="Hhxd1lZX3HtdeKMK0ha0lUJOJVljpreSnIz5diQ8jHk=" name="csrf-token" />
    </head>
    <body>

    <h1>Who said Puppet was hard?</h1>

    </body>
    </html>
