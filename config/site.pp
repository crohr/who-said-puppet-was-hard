include ntp
include rvm
include apache

user {"deploy":
  ensure => present,
  home => "/home/deploy",
  managehome => true,
  shell => "/bin/bash"
}

ssh_authorized_key{ "deploy-key":
  ensure => present,
  user => "deploy",
  key => "AAAAB3NzaC1kc3MAAACBANr+ZLQEw9kLL4Bu0Vx5eSnZtN/lwRUvh1tYvUNwvzc84W7MiqrhF0QfSC6iWBr65J0UpNYzJnBsKXOrArsdainOUjpBHZce6+0jHw2WuZ1qdX3BY5nFExG3WO9fZQup8X1dWrA+qaYuqECfpJs394aBILajCeQoEZm265ifQEalAAAAFQCfmvr9ocbIDVkO/khU0PpeBSNjiQAAAIEAqVgB6k9Q1OvHbRmvnb5f6+ttLgmZ+b1f0fWS+Ez0wYF9+qsounLO7OSiuZSKUu8oosVRhCO2bKyWKjqauokg66CBlgFUkEODcef4xeeveb7s1waH5NoxC07S3adtMB1xreOGmrTLu+kWdZQsACXpdzDSO6aLVO+8tDbk1F48LaoAAACABqc3YCmDBQEVXbPI+glq6UAhibkccFjsy9zR6Eqg8usdeFVHFzL8OT1JHgOm7hG3psNHkZhyN1ErTsagmpG5vy+tdUad5xHS4agLALhGfX1sywd6oqGm4vsjc/k9Ed8DH/0DgPXMEXjCebtLpPS/87BxBSpzr4DgP44qJryEn1g=",
  type => "ssh-dss"
}

rvm_system_ruby { 'ruby-1.9.3-p286':
  ensure => 'present',
  default_use => true
}

rvm::system_user { 'deploy':
  require => User["deploy"]
}

rvm_gemset { "ruby-1.9.3-p286@global":
  ensure => present,
  require => Rvm_system_ruby['ruby-1.9.3-p286']
}

rvm_gem { 'ruby-1.9.3-p286@global/bundler':
  ensure => '1.2.1',
  require => Rvm_gemset['ruby-1.9.3-p286@global']
}

class { 'rvm::passenger::apache':
  version => '3.0.11',
  ruby_version => 'ruby-1.9.3-p286',
  mininstances => '1',
  maxinstancesperapp => '0',
  maxpoolsize => '5'
}

apache::vhost { 'my-server.com':
  priority      => '10',
  port          => '80',
  docroot       => '/home/deploy/apps/who-said-puppet-was-hard/current',
  serveradmin   => 'support@my-server.com',
  ensure        => present
}

# The following is required for apache::vhost to work. Will be
# overwritten by cap deploy:setup.
file { ["/home/deploy/apps", "/home/deploy/apps/who-said-puppet-was-hard"]:
  ensure => directory,
  owner => "deploy",
  group => "deploy",
  require => User["deploy"]
}

file { "/home/deploy/apps/who-said-puppet-was-hard/current":
  ensure => link,
  target => "/dev/null",
  owner => "deploy",
  group => "deploy",
  require => File["/home/deploy/apps/who-said-puppet-was-hard"]
}
