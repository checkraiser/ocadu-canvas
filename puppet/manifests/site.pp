import 'nodes.pp'
$puppetserver = 'puppet.example.com'

filebucket { "main":
  server => "puppet.example.com",
  path => false,
}

File { backup => "main" }
