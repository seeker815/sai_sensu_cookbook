#
# Cookbook Name:: sai_sensu
# Recipe:: server

#  Install Sensu server


 
apt_repository 'sensu' do
  key   'http://repositories.sensuapp.org/apt/pubkey.gpg'
  uri   'http://repositories.sensuapp.org/apt'
  distribution  'sensu'
  components [ 'main' ]
end

package 'sensu' do 
  notifies :restart, 'service[sensu-server]'
end

file '/etc/sensu/config.json' do 
  owner 'sensu'
  group 'sensu'
  mode '644'
  content JSON.pretty_generate(node['sensu']['config'])
  notifies :restart, 'service[sensu-server]'
end


service 'sensu-server' do
  supports :start => true, :stop => true, :restart => true
  action [:enable, :start]
end

