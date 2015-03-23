[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/chef/chef-provisioning?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# chef-provisioning-azure

Implementation of an Azure driver that relies on the Azure SDK for Ruby. 

## What does it do?

It can provision and converge a host on Azure with a recipe like the following:

```ruby
require 'chef/provisioning/azure_driver'
with_driver 'azure'

machine_options = {
    :bootstrap_options => {
      :cloud_service_name => 'chefprovisioning', #required
      :storage_account_name => 'chefprovisioning', #required
      :vm_size => "Small", #required #Case sensitive
      :location => 'West US', #required
      :tcp_endpoints => '80:80' #optional
    },
    :image_id => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_1-LTS-amd64-server-20140927-en-us-30GB', #required
    # Until SSH keys are supported (soon)
    :password => "chefm3t4l\\m/" #required
}

machine 'toad' do
  machine_options machine_options
end
```
 
## Supported Features
 * Automatic creation and teardown of Cloud Services
 * Public (OS) images and captured User (VM) images 
 * Up to date (February 2015) VM sizes including 'D', 'DS' and 'G' sizes.
 * Custom TCP/UDP endpoints per VM role
 * Linux VMs, SSH external bootstrap via public port

## Currently untested/Known issues
 * Windows/WinRM bootstrap
 * Load-balanced sets
 * Availability sets/Fault domains
 * Cloud Service autoscaling
 * Endpoint monitoring
 * Additional disk volumes
 * Affinity groups
 * Direct server return IP addresses
 * Reserved/Static IP addresses
 * Virtual network allocation
 * Bootstrap via internal (private) addresses
 * CDN/TrafficManager
 * Non-IaaS Azure services (e.g CDN/TrafficManager Service Bus, Azure SQL Database, Media Services, Redis Cache)

Currently you have to specify the password you want the initial user to have in your recipe. No, this will not be for very long.

### Setting your credentials
Download the Azure credential file from here: https://manage.windowsazure.com/publishsettings/index?client=xplat  
ID field in the file is your `subscription id`
See [knife-azure](https://github.com/chef/knife-azure#configuration) plugin's config section for more info on converting between formats  

Put the right values in ~/.azure/config so that it looks like the following:

```
[default]
management_certificate = "/Users/YOU/.azure/azure.pem"
subscription_id = "YOUR_SUBSCRIPTION_ID"
```

If you need to generate a certificate for Azure on OSX / Linux you can do it with the following:

```shell 
openssl req \
  -x509 -nodes -days 365 \
  -newkey rsa:1024 -keyout azure.pem -out azure.pem
```

followed by conversion to the DER format for Azure:

```shell
openssl x509 -inform pem -in azure.pem -outform der -out azure.cer
```
