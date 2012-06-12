# Import all exported ssh keys and add to known_hosts
class ssh::importkeys {
  Sshkey <<| |>> { ensure => present }
}
