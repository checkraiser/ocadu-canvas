class canvas::load_balancer ($workers)  {

  include canvas::base
  include canvas::virtual
  realize (Canvas_user['nginx'])
 
  use_flag { 'nginx-gzip':
    package => 'www-servers/nginx',
    flag    => 'nginx_modules_http_gzip_static',
  }

  # Install Nginx
  package { 'nginx':
    ensure 	=> present,
    require	=> [Use_flag['nginx-gzip'],Canvas_user['nginx']],
  }

  # Copy config
  file{ 'nginx-conf': 
    ensure	=> present,
    path	=> '/etc/nginx/nginx.conf',
    source	=> 'puppet:///modules/canvas/load_balancer/nginx.conf',
    owner	=> 'nginx',
    group	=> 'nginx',
    require	=> Package['nginx'],
    notify	=> Service['nginx'],
  }
 
  # Copy upstream config. Relies on $workers
  file { 'upstream-conf':
    ensure	=> present,
    path    	=> '/etc/nginx/upstream.conf',
    content 	=> template('canvas/upstream.conf.erb'),
    owner	=> 'nginx',
    group	=> 'nginx',
    require 	=> Package['nginx'],
    notify	=> Service['nginx'],
  }

  # Copy certificates
  file { 'certs' :
    ensure 	=> directory, 
    recurse	=> true,
    path 	=> '/etc/nginx/certificates',
    source 	=> 'puppet:///modules/canvas/certificates',
    owner	=> 'nginx',
    group	=> 'nginx',
    require 	=> Package['nginx'],
  } 

  # Start service
  service { 'nginx' :
    ensure      => running,
    hasstatus   => true,
    hasrestart  => true, 
    enable      => true,
    require     => [Package['nginx'],File['nginx-conf'],File['upstream-conf']],
  }

  # Copy maintenance files
  file { 'maintenance':
    path    => '/var/www/canvas-maintenance',
    ensure  => directory,
    source  => 'puppet:///modules/canvas/load_balancer/maintenance',
    recurse => true,
    group   => canvas,
    owner   => canvas,
    require => Canvas_user['canvas'],
  }
}
