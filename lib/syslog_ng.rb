module SyslogNg

  # Define options for this plugin via the <tt>configure</tt> method
  # in your application manifest:
  #
  #   configure(:syslog_ng => {:foo => true})
  #
  # Then include the plugin and call the recipe(s) you need:
  #
  #  plugin :syslog_ng
  #  recipe :syslog_ng
  def syslog_ng
    package 'syslog-ng', :ensure => :installed
    service 'syslog-ng', :ensure => :running, :enable => true, :require => package('syslog-ng')

    service 'sysklogd', :ensure => false, :enable => false

    file '/etc/syslog-ng/syslog-ng.conf', 
      :content => template(File.join(File.dirname(__FILE__), '..', 'templates', 'syslog-ng.conf.erb'), binding),
      :mode => '644',
      :require => package('syslog-ng'),
      :notify => service('syslog-ng')
  end

  def syslog_ng_centralized_log_server
    extra_conf = template(File.join(File.dirname(__FILE__), '..', 'templates', 'log-server-syslog-ng.conf.erb'), binding)
    configure :syslog_ng => {
                              :options => {
                                :chain_hostnames => 'off',
                                :sync => 0,
                                :dir_owner => 'root',
                                :dir_group => 'admin',
                                :stats => 43200,
                                :use_dns => 'yes',
                                :dns_cache => 'yes',
                                :dns_cache_size => 100,
                                :dns_cache_expire => 3600,
                                :dns_cache_expire_failed => 600,
                                :keep_hostname => 'yes',
                                :long_hostnames => 'on',
                                :use_fqdn => 'no',
                                :log_msg_size => 1048576,
                                :log_fifo_size => 1000
                              },
                              :extra => extra_conf
                            }
    syslog_ng

    logrotate_options = configuration[:syslog_ng][:log_server_rotate_options] || 
    logrotate_options ||= %w(daily missingok compress sharedscripts create ) << "create #{configuration[:user]} #{configuration[:group] || configuration[:user]} 440"
    if configuration[:syslog_ng][:host_in_file_path]
      logrotate '/var/log/rails/*/*.log', :options => logrotate_options
    else
      logrotate '/var/log/rails/*.log', :options => logrotate_options
    end
  end

  def syslog_ng_rails_client
    extra_conf = template(File.join(File.dirname(__FILE__), '..', 'templates', 'rails-client-syslog-ng.conf.erb'), binding)

    configure :syslog_ng => {
                :options => {
                  :chain_hostnames => 'off',
                  :long_hostnames => 'on',
                  :use_fqdn => 'on',
                  :sync => 0,
                  :stats => 43200,
                  :log_msg_size => 1048576
                },
                :extra => extra_conf
              }
    vhost_extra = configuration[:passenger][:vhost_extra] || ""
    configure :passenger => {
      :vhost_extra => vhost_extra + %Q{\n  CustomLog \"| logger -p local7.info -t passenger\" vhost_combined}
    }

    syslog_ng
  end

end
