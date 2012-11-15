# Who said Puppet was hard?

Example code for provisioning a server in 5' and install a Rails app on
top of it.

## Setup

    rails new who-said-puppet-was-hard -T --skip-bundle
    cd who-said-puppet-was-hard/

    echo 'ruby "1.9.3"' >> Gemfile
    echo 'gem "librarian-puppet", "0.9.3", :group => :development' >> Gemfile
    echo 'gem "capistrano", :group => :development' >> Gemfile
    echo 'gem "rvm-capistrano", :group => :development' >> Gemfile

    bundle install
    capify .
    librarian-puppet init

## Puppetfile


Fetch modules:

    librarian-puppet install

## config/site.pp



## config/deploy.rb

Add this at the end of your `config/deploy.rb` file:

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