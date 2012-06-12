class canvas::deploy {

  include canvas::base
  include canvas::virtual
  realize Canvas_user['deploy']

  # Install FFI package, needed for gem installation 
  exec { 'install-ffi':
    command     => '/usr/bin/emerge dev-ruby/ffi',
    environment => ['USE=threads ruby_targets_ruby18 ruby_targets_ree18'],
    unless      => '/usr/bin/equery list dev-ruby/ffi',
  }

  class { 'canvas::code':
    owner       => 'deploy',
    group	=> 'deploy',
    destination	=> '/var/rails',
    require	=> Canvas_user['deploy'],
  }

  # Add upstream remote
  exec { 'git-upstream':
    command => '/usr/bin/git remote add --track stable upstream https://github.com/instructure/canvas-lms.git',
    cwd     => '/var/rails/canvas',
    unless  => '/usr/bin/git remote show upstream',
    user    => 'deploy',
    require => Class['canvas::code'],
  }

  # Install Capistrano
  gem {'capistrano': ensure => '2.9.0'}

  # Capify
  exec { 'capify':
    command => '/usr/bin/capify .',
    cwd     => '/var/rails/canvas',
    creates => '/var/rails/canvas/Capfile',
    require => [Class['canvas::code'], Gem['capistrano']],
    unless  => '/usr/bin/test -e Capfile',
  }
  
}
