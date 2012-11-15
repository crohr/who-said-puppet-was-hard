$application = "who-said-puppet-was-hard"
$deploy_to = "/home/deploy/apps"
$deploy_user = "deploy"
$public_key = "AAAAB3NzaC1kc3MAAACBANr+ZLQEw9kLL4Bu0Vx5eSnZtN/lwRUvh1tYvUNwvzc84W7MiqrhF0QfSC6iWBr65J0UpNYzJnBsKXOrArsdainOUjpBHZce6+0jHw2WuZ1qdX3BY5nFExG3WO9fZQup8X1dWrA+qaYuqECfpJs394aBILajCeQoEZm265ifQEalAAAAFQCfmvr9ocbIDVkO/khU0PpeBSNjiQAAAIEAqVgB6k9Q1OvHbRmvnb5f6+ttLgmZ+b1f0fWS+Ez0wYF9+qsounLO7OSiuZSKUu8oosVRhCO2bKyWKjqauokg66CBlgFUkEODcef4xeeveb7s1waH5NoxC07S3adtMB1xreOGmrTLu+kWdZQsACXpdzDSO6aLVO+8tDbk1F48LaoAAACABqc3YCmDBQEVXbPI+glq6UAhibkccFjsy9zR6Eqg8usdeFVHFzL8OT1JHgOm7hG3psNHkZhyN1ErTsagmpG5vy+tdUad5xHS4agLALhGfX1sywd6oqGm4vsjc/k9Ed8DH/0DgPXMEXjCebtLpPS/87BxBSpzr4DgP44qJryEn1g="
$public_key_type = "ssh-dss"
$main_ruby = "1.9.3-p286"
$passenger_version = '3.0.18'
$bundler_version = '1.2.1'
$main_ruby_location = "/home/$deploy_user/.rbenv/versions/$main_ruby"
$passenger_location = "$main_ruby_location/lib/ruby/gems/1.9.1/gems/passenger-$passenger_version"
$mod_passenger_location = "$passenger_location/ext/apache2/mod_passenger.so"

include ntp
include apache
require apache::mod::dev

user { "$deploy_user":
  ensure => present,
  home => "/home/$deploy_user",
  managehome => true,
  shell => "/bin/bash"
}

ssh_authorized_key{ "$deploy_user-key":
  ensure => present,
  user => $deploy_user,
  key => "$public_key",
  type => "$public_key_type"
}

rbenv::install { "$deploy_user":
  group => "$deploy_user"
}

rbenv::compile { "$main_ruby":
  user => "$deploy_user",
  global => true
}

rbenv::gem { "bundler":
  user => "$deploy_user",
  ruby => "$main_ruby",
  ensure => "$bundler_version"
}

rbenv::gem { "passenger":
  user => "$deploy_user",
  ruby => "$main_ruby",
  ensure => "$passenger_version"
}

package{ "libcurl4-openssl-dev":
  ensure => installed
}

exec{ "passenger-install-apache2-module -a":
  path    => [ "/home/$deploy_user/.rbenv/shims", "/home/$deploy_user/.rbenv/bin", '/usr/bin', '/bin', '/usr/local/bin' ],
  unless => "[ -f $mod_passenger_location ]",
  require => [Package["libcurl4-openssl-dev"], Rbenvgem["$deploy_user/$main_ruby/passenger/$passenger_version"]]
}

file {"/etc/apache2/conf.d/passenger.conf":
  ensure => present,
  content => "LoadModule passenger_module $mod_passenger_location\nPassengerRoot $passenger_location\nPassengerRuby $main_ruby_location/bin/ruby\n",
  require => Exec["passenger-install-apache2-module -a"],
  notify => Service["httpd"]
}

apache::vhost { 'my-server.com':
  priority      => '10',
  port          => '80',
  docroot       => "$deploy_to/$application/current/public",
  serveradmin   => 'support@my-server.com',
  ensure        => present
}

# The following is required for apache::vhost to work since it needs the
# docroot parent hierarchy to be created. There is probably a better way
# to do this.
file {
  [
    "$deploy_to",
    "$deploy_to/$application",
    "$deploy_to/$application/releases",
    "$deploy_to/$application/releases/0"
  ]:
    ensure => directory,
    replace => false,
    owner => $deploy_user,
    group => $deploy_user,
    require => User[$deploy_user]
}

file { "$deploy_to/$application/current":
  ensure => link,
  replace => false,
  target => "$deploy_to/$application/releases/0",
  owner => $deploy_user,
  group => $deploy_user,
  require => File["$deploy_to/$application/releases/0"]
}

file { "$deploy_to/$application/current/public":
  ensure => directory,
  replace => false,
  owner => $deploy_user,
  group => $deploy_user,
  require => File["$deploy_to/$application/current"]
}
