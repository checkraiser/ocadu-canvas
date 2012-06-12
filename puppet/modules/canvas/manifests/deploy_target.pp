class canvas::deploy_target {

  realize Canvas_user['canvas']

  # Make sure rails folder exists
  file { '/var/rails':
    ensure 	 => directory,
    owner	 => 'canvas',
    group	 => 'canvas',
    require	 => Canvas_user['canvas'],
  }
  
  # Add key for deploy machine
  ssh_authorized_key { 'deploy':
    ensure 	=> present,
    key 	=> 'Key goes here', # Should match key from files/ssh-keys/deploy.pub
    type	=> 'ssh-rsa',
    user   	=> 'canvas',
  }
  
  # Create canvas folders and permissions
  #file {'/var/rails/canvas' : owner => 'canvas', recurse => true, require => Exec['checkout-canvas'], }
  #file {'/var/rails/canvas/config/environment.rb'	 : owner => 'canvas', require => File['/var/rails/canvas'] } 
  #file { '/var/rails/canvas/log'                         : ensure => directory, owner => 'canvas', require => File['/var/rails/canvas'], recurse => true }
  #file { '/var/rails/canvas/tmp'                         : ensure => directory, owner => 'canvas', require => File['/var/rails/canvas'], recurse => true }
  #file { '/var/rails/canvas/public/assets/'              : ensure => directory, owner => 'canvas', require => File['/var/rails/canvas'], recurse => true }
  #file { '/var/rails/canvas/public/stylesheets/compiled' : ensure => directory, owner => 'canvas', require => File['/var/rails/canvas'], recurse => true }
  #file { '/var/rails/canvas/tmp/pids'                    : ensure => directory, owner => 'canvas', require => File['/var/rails/canvas/tmp'] }


}
