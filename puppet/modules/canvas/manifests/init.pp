class canvas {

   Package {
    provider => $operatingsystem? {
      gentoo => 'portage',
    }
  }

  # Add entry to emerge USE flags
  define use_flag($package, $flag) {
    $line = "${package} ${flag}"
    $file = '/etc/portage/package.use'

    exec { 'add_use_flag':
      command	=> "/bin/echo '${line}' >> '${file}'",
      unless 	=> "/bin/grep -qFx '${line}' '${file}' ",
    }
  }
  
  
  # Unmasks and installs a masked package
  define masked_package() {
    # Unmask
    exec { "unmask-${name}":
      command	=> "/bin/echo ${name} ~${architecture} >> /etc/portage/package.keywords",
      unless 	=> "/bin/cat /etc/portage/package.keywords | /bin/grep '${name}'",
    }
	
    # Install. Uses Exec instead of Package to work around strange eix error that sometimes occurs
    exec { "install-${name}":
      command => "/usr/bin/emerge ${name}",
      unless  => "/usr/bin/equery list ${name}",
      require => Exec["unmask-${name}"],
    }
  }
 

  # Shortcut to install a gem
  define gem($ensure=present) {

    realize Package['rubygems']

    package { "gem-${name}":
      name     => $name,
      ensure   => $ensure,
      provider => 'gem',
      require  => Package['rubygems'],
    }
  }
 

  define system_ruby() {
    exec { 'system-ruby':
      command   => "/usr/bin/eselect ruby set $name",
      unless    => "/usr/bin/eselect ruby show | /bin/grep '${name}'",
    }
  }
 

  define line ($line, $file) {
    exec { "line-${line}-${file}":
      command   => "/bin/echo '${line}' >> '${file}'",
      unless    => "/bin/grep -qFx '${line}' '${file}' ",
    } 
  }

  # Users and related files
  define canvas_user($username, $id, $home=true, $shell='/bin/bash') {
    # Create group
    group { $username:
      ensure => present,
      gid    => $id,
    }
    
    # Create user
    user { $username:
      ensure      => present,
      shell       => $shell,
      uid         => $id, 
      gid         => $username,
      managehome  => $home,
      require     => Group[$username],
    }

    # If we are managing a home folder, include SSH details
    if $home {
      # Copy private ssh key
      file { "/home/${username}/.ssh/id_rsa":
        ensure	=> present,
        source	=> "puppet:///modules/canvas/ssh-keys/${username}",
        owner	=> $username,
        group	=> $username,
        mode	=> 600,
        require	=> User[$username],
      }
    
      # Copy public ssh key
      file { "/home/${username}/.ssh/id_rsa.pub":
        ensure	=> present,
        source	=> "puppet:///modules/canvas/ssh-keys/${username}.pub",
        owner	=> $username,
        group	=> $username,
        mode	=> 600,
        require	=> User[$username],
      }

      # Copy known hosts file
      file { "/home/${username}/.ssh/known_hosts":
        ensure 	=> present,
        source	=> "puppet:///modules/canvas/ssh-keys/known_hosts",
        owner	=> $username,
        group	=> $username,
        mode	=> 600,
        require	=> User[$username],
      }
    }
  }
}
