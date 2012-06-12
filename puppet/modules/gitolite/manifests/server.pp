class gitolite::server {
  
  include gitolite::params

  user { 'git':
    ensure 	=> present,
    managehome 	=> true,
    shell 	=> '/bin/bash', 
  }

  $rootFolder = "${gitolite::params::rootdir}"
  $keyFolder  = "${gitolite::params::keydir}"
  $confFolder = "${gitolite::params::confdir}"

  file { $rootFolder:
    ensure	=> directory,
    owner	=> 'git',
    require   	=> User['git'],
  }
  
  file { $keyFolder:
    ensure 	=> directory,
    owner	=> 'git',
    require	=> File[$rootFolder],
  }

  file { $confFolder:
    ensure      => directory,
    owner       => 'git',
    require     => File[$rootFolder],
  }

  package { 'gitolite':
    ensure 	=> present,
    provider 	=> $operatingsystem? {
      gentoo 	=> 'portage',
    }
  }
  
  # At this point, gitolite needs to be configured. See http://sitaramc.github.com/gitolite/master-toc.html
}
