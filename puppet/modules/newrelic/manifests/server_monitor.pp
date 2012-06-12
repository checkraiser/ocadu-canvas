class newrelic::server_monitor {
  include newrelic::params

  # Unmask sysmond
  exec { 'unmask-sysmond':
    command	=> '/bin/echo sys-apps/newrelic-sysmond ~amd64 >> /etc/portage/package.keywords',
    unless 	=> '/bin/cat /etc/portage/package.keywords | /bin/grep sys-apps/newrelic-sysmond',
  } 

  exec { 'install-sysmond':
    command	=> '/usr/bin/emerge sys-apps/newrelic-sysmond',
    unless  	=> '/usr/bin/equery list sys-apps/newrelic-sysmond',
    require   	=> Exec['unmask-sysmond'],
  }

  # Copy config
  $license_key = $newrelic::params::license_key
  file { 'nr-config':
    path	=> '/etc/newrelic/nrsysmond.cfg',
    ensure	=> present,
    content  	=> template('newrelic/nrsysmond.cfg.erb'),
    require 	=> Exec['install-sysmond'],
    notify	=> Service['newrelic'], 
  }

  # Copy fixed init script
  file { 'nr-init':
    path   	=>'/etc/init.d/newrelic-sysmond',
    ensure 	=> present,
    source 	=> 'puppet:///modules/newrelic/newrelic-init',
    require	=> Exec['install-sysmond'],
    mode     	=> 755,
  }

  # Start service
  service { 'newrelic':
    name       => 'newrelic-sysmond',
    ensure     => running,
    hasstatus  => true,
    hasrestart => true, 
    enable     => true,
    require    => [File['nr-init'],File['nr-config']],
  }
}
