# This class will checkout a copy of the code to $destination
# This is not to be used for application servers. They get their code from the deploy process

class canvas::code ($owner='canvas', group='canvas', $destination='/var/rails') {

  package { 'git': ensure => present}

  # Grab canvas code
  file { 'canvas-home':
    path	=> $destination,
    ensure  	=> directory,
    owner   	=> $owner,
    group   	=> $group,
    mode	=> 750,
    require 	=> User[$owner],
  }
  
  # TODO: make git server a class param
  exec { 'checkout-canvas':
    command     => "git clone git@puppet.example.ca:canvas ${destination}/canvas",
    path        => '/usr/bin',
    creates     => "${destination}/canvas",
    user        => $owner,
    require     => [Package['git'],File['canvas-home']]
  }

  # Make sure user owns all git files
  file { 'repo-perms' :
    path     	=> "${destination}/canvas/.git",
    ensure   	=> present,
    recurse  	=> true,
    owner    	=> $owner,
    group    	=> $group,
    mode   	=> 770,
    require  	=> Exec['checkout-canvas'],
  }

  # Get working tree of git repo
  exec { 'git-checkout':
    command     => '/usr/bin/git checkout stable',
    cwd         => "${destination}/canvas",
    creates     => "${destination}/canvas/app",
    user        => $owner,
    require     => File['repo-perms'],
  }
}
