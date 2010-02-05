require File.join(File.dirname(__FILE__), 'spec_helper.rb')

class SyslogNgManifest < Moonshine::Manifest::Rails
  plugin :syslog_ng
end

describe "A manifest with the SyslogNg plugin" do

  before do
    @manifest = SyslogNgManifest.new
  end

  it "should be executable" do
    @manifest.syslog_ng
    @manifest.syslog_ng_centralized_log_server
    @manifest.syslog_ng_rails_client
    @manifest.should be_executable
  end

  shared_examples_for 'main syslog-ng configuration' do
    it 'should install the syslog-ng package (duh)' do
      @manifest.packages.keys.should include('syslog-ng')
    end

    it 'should configure and run the syslog-ng service' do
      @manifest.services.keys.should include('syslog-ng')
      @manifest.services['syslog-ng'].ensure.should == :running
    end

    it 'should install the main syslog-ng configuration file' do
      @manifest.files['/etc/syslog-ng/syslog-ng.conf'].should_not be(nil)
    end
  end

  describe 'using the main syslog_ng recipe' do
    before do
      @manifest.syslog_ng
    end

    it_should_behave_like 'main syslog-ng configuration'

    it 'should handle options' do
      @manifest.files['/etc/syslog-ng/syslog-ng.conf'].content.should match(/use_dns\(no\)/)
      @manifest.files['/etc/syslog-ng/syslog-ng.conf'].content.should_not match(/omgwtfbbq/)
      @manifest.syslog_ng({ :options => { :use_dns => 'yes' }, :extra => 'omgwtfbbq'})
      @manifest.files['/etc/syslog-ng/syslog-ng.conf'].content.should match(/use_dns\(yes\)/)
      @manifest.files['/etc/syslog-ng/syslog-ng.conf'].content.should match(/^omgwtfbbq/)
    end
  end

  shared_examples_for 'networking is configured' do
    it 'should be configured with specified IP and port' do
      listen = /udp\(ip\(10\.0\.4\.200\) port\(515\)\)/
      @manifest.files['/etc/syslog-ng/syslog-ng.conf'].content.should match(listen)
    end
  end

  describe 'using the syslog_ng_centralized_log_server recipe' do
    before do
      opts = { :log_server_ip => '10.0.4.200', :log_server_port => 515 }
      @manifest.syslog_ng_centralized_log_server(opts)
    end

    it_should_behave_like 'main syslog-ng configuration'
    it_should_behave_like 'networking is configured'

    it 'should define a source' do
      @manifest.files['/etc/syslog-ng/syslog-ng.conf'].content.should match(/source app_cluster/)
    end
  end

  describe 'using the syslog_ng_rails_client recipe' do
    before do
      opts = { :log_server_ip => '10.0.4.200', :log_server_port => 515 }
      @manifest.syslog_ng_rails_client(opts)
    end

    it_should_behave_like 'main syslog-ng configuration'
    it_should_behave_like 'networking is configured'

    it 'should define a destination' do
      @manifest.files['/etc/syslog-ng/syslog-ng.conf'].content.should match(/destination log_server/)
    end
  end
end
