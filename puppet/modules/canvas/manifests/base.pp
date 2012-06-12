class canvas::base {
  # Enable puppet agent
  service { 'puppet':
    ensure      => running,
    hasstatus   => true,
    hasrestart  => true,
    enable      => true,
  }
  
  # Hosts file
  file { '/etc/hosts':
    ensure => present,
    source => 'puppet:///modules/canvas/hosts',
    owner  => 'root',
    group  => 'root',
    mode   => 644,
  }

  # ntpd
  service { 'ntpd' : 
    ensure     => running, 
    hasstatus  => true,
    hasrestart => true,
    enable     => true,
  }

  # logrotate
  package { 'app-admin/logrotate': ensure => present,}

}
