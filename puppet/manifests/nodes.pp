node 'puppet.example.com' {
  include newrelic::server_monitor
}

node 'git.example.com' {
  include gitolite::server
}

node 'canvas1.example.com' {
  include canvas::application_server
  include canvas::job_runner
  include canvas::storage
  include newrelic::server_monitor
}

node 'canvas2.example.com' {
  include canvas::application_server
  include canvas::job_runner
  include canvas::storage
  include newrelic::server_monitor
}

node 'canvasweb.example.com' {
  class {'canvas::load_balancer': workers => ['canvas1.example.com', 'canvas2.example.com']}
  include newrelic::server_monitor
}
