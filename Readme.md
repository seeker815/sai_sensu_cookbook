# sai_sensu

Installs [Sensu-server](https://sensuapp.org) and allows user to configure 

##Requirements

Depends on [apt cookbook](https://supermarket.chef.io/cookbooks/apt). 
We currently support

- Ubuntu 12.04
- Ubuntu 14.04


##Attributes

Add your configs to attribute file `default.rb`, this is where your sensu server
configuration would go

##Recipes

Coobook contains `default.rb` and `server.rb`.

`default.rb` is used for including the `server.rb`.

`server.rb` contains resources for sensu-server install.

