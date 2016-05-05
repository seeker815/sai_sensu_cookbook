#!/usr/bin/env ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :
ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'
ENV['PATH'] = '/opt/chefdk/bin:/usr/local/bin:/usr/bin:%s' % ENV['PATH']

Vagrant.configure('2') do |config|
  config.omnibus.chef_version = :latest
  config.berkshelf.enabled = true
  config.vm.define 'vagrant' do |node|
    node.vm.box = 'bento/ubuntu-14.04'
    node.vm.hostname = 'vagrant'
    node.vm.network :private_network, ip: '10.10.10.13'
    node.vm.provision :chef_solo do |chef|
      chef.log_level = :info
      chef.json = {
        'minitest' => {
          'recipes' => ['sai_sensu::server']
        },
        'sensu' => {
          'config' => {
            "transport" => {
              "name" => "rabbitmq",
              "reconnect_on_error" => true
            },
            'rabbitmq' => {
              "host" => "localhost",
              "port" => 5672,
              "user" => "admin",
              "password" => "changeme",
              "vhost" => "/",
              "heartbeat" => 30
            }
            
          }
        }
      } 
      chef.run_list = %w(
        recipe[apt]
        recipe[bjn_rabbitmq]
        recipe[bjn_redis2]
        recipe[sai_sensu]
        recipe[minitest-handler]
      )
    end
  end
end