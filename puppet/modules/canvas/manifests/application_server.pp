 class canvas::application_server {
  
  include canvas::base
  include canvas::virtual
  include canvas::deploy_target


  # Dependencies
  package {
    [ 'git',
      'curl',
      'ruby',
      'sys-libs/zlib',
      'rake',
      'libxml2',
      'libxslt',
      'dev-ruby/httpclient',
      'nano',
      'media-gfx/imagemagick',
      'redis',
      'openssl',
      'dev-lang/ruby-enterprise',
      'postgresql-base',
      'sqlite',
      'dev-db/mysql',
      'virtual/jre',
      'unzip',
    ]:
    ensure 	=> present,
  }
  
  # Install FFI package 
  exec { 'install-ffi':
    command 	=> '/usr/bin/emerge dev-ruby/ffi',
    environment	=> ['USE=threads ruby_targets_ruby18 ruby_targets_ree18'],
    unless  	=> '/usr/bin/equery list dev-ruby/ffi',
  }
  
  masked_package { 'net-libs/nodejs': }
  gem { 'passenger': ensure=>'3.0.9' }
  gem { 'bundler': }
  
  # Make REE system Ruby
  system_ruby{'rubyee18': require => Package['dev-lang/ruby-enterprise'] }
  
  realize (Canvas_user['canvas'])
  realize (Canvas_user['nginx'])
  
  # Copy tuned ree executable
  file { 'tuned-ree' :  
    ensure      => present, 
    path        => '/home/canvas/tuned-ree',
    source      => 'puppet:///modules/canvas/application_server/tuned-ree',
    owner       => 'canvas',
    group       => 'canvas',
    mode        => 755,
    require     => Canvas_user['canvas'],
  }
  
  # Redis service and config
  service { 'redis':
    ensure   	=> "running",
    hasstatus 	=> true, 
    hasrestart 	=> true,
    enable 	=> true,
    require	=> Package['redis'],
  }

  file { 'redis-conf':
    ensure => present,
    path   => '/etc/redis.conf',
    source => 'puppet:///modules/canvas/application_server/redis.conf',
    owner  => 'redis',
    group  => 'redis',
    mode   => 644,
    notify => Service['redis'],
  }
  
  # Run passenger-nginx install
  # Can't install from portage because it doesn't like to compile with passenger 
  exec { 'install-nginx':
    command 	=> '/usr/bin/sudo /usr/bin/passenger-install-nginx-module --auto --auto-download --prefix=/opt/nginx --extra-configure-flags="--with-http_gzip_static_module"',
    creates 	=> '/opt/nginx',
    require 	=> [Gem['passenger'],Canvas_user['nginx']],
  }

  # Copy config
  file { 'nginx-conf':
    ensure 	=> file,
    path 	=> '/opt/nginx/conf/nginx.conf',
    source 	=> 'puppet:///modules/canvas/application_server/nginx.conf', 
    owner 	=> 'nginx',
    group 	=> 'nginx',
    require 	=> [Exec['install-nginx'],Canvas_user['nginx']],
    notify	=> [Service['nginx']],
  }

  # Copy certificates
  file { 'certs' :
    ensure 	=> directory, 
    recurse	=> true,
    path 	=> '/opt/nginx/certificates',
    source 	=> 'puppet:///modules/canvas/certificates',
    owner	=> 'nginx',
    group	=> 'nginx',
    require 	=> [Exec['install-nginx'],Canvas_user['nginx']],
  }  

  # Copy init file
  file { 'nginx-init' :
    ensure 	=> present, 
    path 	=> '/etc/init.d/nginx',
    source	=> 'puppet:///modules/canvas/application_server/nginx-init',
    owner	=> 'root',
    group	=> 'root',
    mode	=> 755,
  }

  # Start service
  service { 'nginx-init' :
    name	=> 'nginx',
    ensure	=> running,
    hasstatus	=> true,
    hasrestart  => false,
    enable	=> true,
    require	=> [File['certs'],  File['nginx-conf'], Exec['install-nginx']],
  }

  # Log rotate config. Package is installed by ::base
  file { 'logrotate':
    ensure  => present,
    path    => '/etc/logrotate.d/canvas',
    source  => 'puppet:///modules/canvas/application_server/canvas-logrotate',
    owner   => 'root',
    group   => 'root',
    mode    => 644,
    require => Package['app-admin/logrotate'],
  }
  
  # Crons!
  cron { 'kill-huge-passengers':
    command => '/bin/kill -9 `/usr/bin/passenger-memory-stats 2>/dev/null | /bin/awk -vORS=" " \'/Rack/{if($4 > 550) print $1}\'` 2>/dev/null',
    user    => 'root',
    minute  => '*',
  }
  
  cron { 'kill-orphan-passengers':
    command => '/bin/kill -9 `/usr/bin/passenger-memory-stats 2>/dev/null | /bin/awk \'/Rack/{print $1}\' | /bin/egrep -e $(/usr/bin/passenger-status | /bin/awk -vORS=" -e" \'/PID/{print $3}\') xxx -v | /bin/awk -vORS=" " \'{print $1}\'` 2>/dev/null',
    user    => 'root',
    minute  => '*',
  }

  cron { 'kill-orphan-workers':
    command => '/bin/kill -9 `/bin/ps -elf 2>/dev/null | /bin/awk \'{if ($5 == 1 && $3 != "root") {print $0}}\' | /bin/grep delayed:run | /bin/awk \'{print $4}\'` 2>/dev/null',
    user    => 'root',
    minute  => '*',
  }

 cron { 'clear-swap':
   command => '[ `free|awk \'/Mem:/{print $4}\'` > `free|awk \'/Swap:/{print $3}\'` -a `free|awk \'/Swap:/{print $3}\'` > 0 ] && (swapoff -a && swapon -a)',
   user    => 'root',
   minute  => '*/5',
 }
}
