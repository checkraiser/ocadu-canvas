OCADU-Canvas
============

A collection of configuration files for OCADU's Canvas LMS environment. 
See https://github.com/instructure/canvas-lms

/puppet: puppet modules for canvas installation. Specific to our environment, but could work as a 
jumping-off point. 

/deploy: Capistrano deploy script and environment settings. Should be dropped into canvas config folder

/tuned-ree: My attempt at tuning REE memory management to run Canvas

/crons: Some cron jobs that we use to keep canvas processes in check