require "bundler/capistrano"

set :application, "who-said-puppet-was-hard"
set :repository,  "https://github.com/crohr/#{application}.git"

set :user, ENV.fetch('REMOTE_USER') { 'deploy' }
set :use_sudo, false
set :deploy_to, "/home/#{user}/apps/#{application}"

set :default_environment, {
  'PATH' => "$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
}

set :bundle_flags, "--deployment --binstubs --shebang ruby-local-exec"

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

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