class canvas::job_runner {

  # Create symlink to init script
  file { 'canvas_init':
    ensure 	=> link,
    path   	=> '/etc/init.d/canvas_init',
    target 	=> '/var/rails/canvas/current/script/canvas_init',
  }

  # Run the service
  service { 'canvas_init':
    ensure 	    => running,
    hasstatus 	=> true,
    hasrestart 	=> true,
    status	    => '/etc/init.d/canvas_init status | /bin/grep PID',
    enable 	    => true,
    require	    => File['canvas_init'],
  }

}
