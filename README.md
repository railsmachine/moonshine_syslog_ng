# Moonshine syslog-ng

### A plugin for [Moonshine](http://github.com/railsmachine/moonshine)

A plugin and recipe for installing and managing [syslog_ng](http://www.balabit.com/network-security/syslog-ng/).

In addition, there are recipes included to setup a centralized log server for your application servers, and a recipe to setup application servers to log to the centralized log server.

### Instructions

* <tt>script/plugin install git://github.com/railsmachine/moonshine_syslog_ng.git</tt>
* Include the plugin in your Moonshine manifest
    <tt>plugin :syslog_ng</tt>
* Choose one of the following syslog_ng recipes, explained below

#### syslog_ng

This is the base syslog_ng recipe. It is responsible for installing the package, and setting it up with some reasonable configuration, and starting it as a service.  There are a few things you can configure here.

First is <tt>:options</tt>. These are the options section of /etc/syslog-ng/syslog-ng.conf. If you don't specificy anything, the Ubuntu defaults are used.

Second is <tt>:extra</tt>. This is an extra configuration to append to the end of /etc/syslog-ng/syslog-ng.conf.

Example usage:

    # Using configure
    configure :syslog_ng => {
                :options => {
                  :chain_hostnames => 'off',
                  :long_hostnames => 'on',
                  :use_fqdn => 'on',
                  :sync => 0,
                  :stats => 43200,
                  :log_msg_size => 1048576
              },
              :extra => '# my extra configuration here'
            }
    plugin :syslog_ng
    recipe :syslog_ng

    # Or using moonshine.yml:
    :syslog_ng:
      :options:
        # note, it is important to quote on, off, yes, and no, as YAML will try to coerce those to booleans (true and false)
        :chain_hostnames: 'off' 
	:long_hostnames: 'on'
	:use_fqdn: 'on'
	:sync: 0
	:stats: 43200
	:log_msg_size: 1048576
    # With corresponding manifest:
    plugin :syslog_ng
    recipe :syslog_ng

#### syslog_ng_centralized_log_server

This uses the underlying <tt>syslog_ng</tt> recipe to setup the host as a centralized log server ready to receive logs from hosts setup with <tt>syslog_ng_rails_client</tt>

This will save rails logs to /var/log/rails/rails-application-environment.log and passenger logs to /var/log/rails/passenger.log.

If you need log rotation, you can use logrotate to handle this for you.

You need to provide additional configuration with the IP address of the log server and a port to listen on:

    # moonshine.yml, note this isn't under the syslog_ng namespace
    :syslog_ng:
      :log_server_ip: 555.555.555.555
      :log_server_port: 515

This sets some <tt>:options</tt> and uses the <tt>:extra</tt>. If you need more customization, it probably would make sense to create a new recipe based on it with whatever options and extra configuration you need.

#### syslog_ng_rails_client

This uses the underlying <tt>syslog_ng</tt> recipe to setup the host to send rails logs to a host setup with <tt>syslog_ng_centralized_log_server</tt>.

For this to catch Apache logging for the passenger vhost, the recipe must be declared BEFORE the passenger recipe (ie <tt>:default_stack</tt>)

You need to provide additional configuration with the IP address of the log server and a port to listen on:

    # moonshine.yml, note this isn't under the syslog_ng namespace
    :syslog_ng:
      :log_server_ip: 555.555.555.555
      :log_server_port: 515
      
This sets some <tt>:options</tt> and uses the <tt>:extra</tt>. If you need more customization, it probably would make sense to create a new recipe based on it with whatever options and extra configuration you need.

In addition to the updates to the manifest, you need to configure Rails to use the syslog instead of its own logger.

    # Gemfile if using Rails 3+ or Rails 2.3 with bundler
    gem 'SyslogLogger', :require => false

    # config/environment.rb if using Rails 2.3
    config.gem 'SyslogLogger', :lib => false

    # config/environments/production.rb
    require 'syslog/logger' 
    # having the name start with rails- is required for the centralized logging to work
    config.logger = Syslog::Logger.new("rails-production")

***
Unless otherwise specified, all content copyright &copy; 2014, [Rails Machine, LLC](http://railsmachine.com)
