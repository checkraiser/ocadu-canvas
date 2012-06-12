class canvas::virtual {
  @canvas_user{'nginx':  username => 'nginx',  id => 1010, home => false, shell => '/sbin/nologin' }
  @canvas_user{'canvas': username => 'canvas', id => 1002 }
  @canvas_user{'deploy': username => 'deploy', id => 1011 }
  @package {'rubygems': ensure => present}
}
