class canvas::storage {
 
  include canvas::params
  include canvas::base

  $sanIP = '1.1.3.1'


  # Packages
  package { 'sys-block/open-iscsi': ensure => present }
  masked_package { 'sys-fs/ocfs2-tools': }


  # Network config
  $ips   = $canvas::params::storageIPs
  $ip    = $ips[$hostname]
  $line1 = "config_eth1=\"${ip} netmask 255.255.255.0 brd 1.1.3.255\""
  $line2 = 'mtu_eth1="9000"'
  $file  = '/etc/conf.d/net'

  line{'eth1-config': line => $line1, file => $file, }
  line{'eth1-mtu':    line=> $line2, file => $file,  require => Line['eth1-config'], }
  
  file {'eth1-init':
    ensure => link,
    path   => '/etc/init.d/net.eth1',
    target => 'net.lo',
    mode   => 755,
  }

  service {'net.eth1':
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    enable     => true,
    require    => File['eth1-init'], 
    subscribe  => [Line['eth1-config'],Line['eth1-mtu']],
  }


  # iSCSI Config
  file {'iscsi-conf':
    ensure  => present,
    path    => '/etc/iscsi/iscsid.conf',
    source  => 'puppet:///modules/canvas/storage/iscsid.conf',
    mode    => 600,
    owner   => 'root',
    group   => 'root',
    require => Package['sys-block/open-iscsi'],
  }

  service { 'iscsid':
    ensure     => running,
    hasstatus  => true,
    hasrestart => true,
    enable     => true,
    require    => [File['iscsi-conf'],Service['net.eth1']],
    subscribe  => File['iscsi-conf'],
  }


  # ISCSI Config
  exec { 'iscsiadm-new':
    command => '/usr/sbin/iscsiadm -m iface -I eth1 --op=new',
    unless  => '/usr/sbin/iscsiadm -m iface --op=show | grep eth1',
  }

  exec { 'iscsiadm-update':
    command => "/usr/sbin/iscsiadm -m iface -I eth1 --op=update -n iface.hwaddress -v ${macaddress_eth1}", 
    unless  => "/usr/sbin/iscsiadm -m iface --op=show | grep ${macaddress_eth1}",
  }

  exec { 'iscsiadm-discovery':
    command => "/usr/sbin/iscsiadm -m discovery -t st -p ${sanIP} -P 1",
    unless  => "/usr/sbin/iscsiadm -m discovery --op show | grep ${sanIP}",
    require => Exec['iscsiadm-update'],
  }


  exec { 'iscsiadm-login':
    command     => '/usr/sbin/iscsiadm -m node -l',
    subscribe   => Exec['iscsiadm-discovery'],
    refreshonly => true,
  }

  exec { 'vgscan':
    command     => '/sbin/vgscan',
    subscribe   => Exec['iscsiadm-login'],
    refreshonly => true,
  }

  exec { 'vgchange':
    command     => '/sbin/vgchange -a y /dev/vgiscsi',
    subscribe   => Exec['vgscan'],
    refreshonly => true,
  }


  # OCFS2 Config
  file {'/etc/ocfs2':
    ensure => directory,
    mode   => 755,
  }

  file {'/etc/ocfs2/cluster.conf':
    ensure  => present,
    source  => 'puppet:///modules/canvas/storage/cluster.conf', 
    mode    => 644,
    owner   => 'root',
    group   => 'root',
    require => File['/etc/ocfs2'],
  }

  file {'/etc/conf.d/ocfs2':
    ensure  => present,
    source  => 'puppet:///modules/canvas/storage/conf.d-ocfs2',
    mode    => 644,
    owner   => 'root',
    group   => 'root',
    require => Masked_package['sys-fs/ocfs2-tools'],
  }
  
  mount {'configfs':
    atboot  => true,
    device  => 'none',
    ensure  => mounted, 
    fstype  => 'configfs',
    name    => '/sys/kernel/config',
    options => 'defaults',
    require => Masked_package['sys-fs/ocfs2-tools'], 
  }

  mount {'dlmfs':
    atboot  => true,
    device  => 'none',
    ensure  => mounted, 
    fstype  => 'ocfs2_dlmfs',
    name    => '/sys/kernel/dlm',
    options => 'defaults',
    require => Masked_package['sys-fs/ocfs2-tools'],
  }

  service { 'ocfs2':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [
      File['/etc/conf.d/ocfs2'],
      File['/etc/ocfs2/cluster.conf'],
      Mount['configfs'],
      Mount['dlmfs'],
    ],
  }

  file {'/mnt/canvasdata': ensure => directory }

  mount {'canvasdata':
    atboot  => false,
    device  => '/dev/vgiscsi/canvasdata',
    ensure  => mounted, 
    fstype  => 'ocfs2',
    name    => '/mnt/canvasdata',
    options => 'noauto,noatime',
    require => [File['/mnt/canvasdata'],Service['ocfs2'],Exec['vgchange']],
  }


  # Local.d scripts
  file { '/etc/local.d/canvasdata.start':
    ensure => present,
    source => 'puppet:///modules/canvas/storage/canvasdata.start',
    mode   => 755,
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/local.d/canvasdata.stop':
    ensure => present,
    source => 'puppet:///modules/canvas/storage/canvasdata.stop',
    mode   => 755,
    owner  => 'root',
    group  => 'root',
  }
}
