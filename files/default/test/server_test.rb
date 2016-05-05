require 'minitest/spec'

def valid_json?(str)
  JSON.parse(str)
  return true
rescue
  return false
end

def command_succeeds?(string)
  `#{string}`
  $?.exitstatus == 0
end

# it has sensu in apt source list
describe_recipe('server') do

  it('has sensu in apt source list') do
    assert(command_succeeds?("cat /etc/apt/sources.list.d/sensu.list | grep sensu"))
  end

  it('has sensu package installed') do
    assert(command_succeeds?("dpkg -s sensu"))
  end

  it('has sensu-server running') do
    assert(command_succeeds?("service sensu-server status"))
  end

  it('has /etc/sensu/config.json setup') do
    assert(command_succeeds?("ls -la /etc/sensu/config.json"))

	  # #validate json for the above
    config_json = File.read('/etc/sensu/config.json')
    assert(valid_json?(config_json))
    #contents of the config.json has rabbitmq
    config_hash = JSON.parse(config_json)   
    assert(config_hash.key?('rabbitmq'))
  end


  it('has no error in logs') do
    assert(!command_succeeds?("grep error /var/log/sensu/sensu-server.log | grep -v 'Detected TCP connection failure'"))
  end

  it('has sensu-server connected to redis') do
    assert(!command_succeeds?("grep 'reconnecting to redis' /var/log/sensu/sensu-server.log"))
  end

end 
