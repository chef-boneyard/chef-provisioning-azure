[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/chef/chef-provisioning?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# chef-provisioning-azure

This is an implementation of an Microsoft Azure driver for [chef-provisioning](/chef/chef-provisioning) that relies on [azure-sdk-for-ruby](https://github.com/stuartpreston/stuartpreston-azure-sdk-for-ruby) and the Azure Service Management API.

## What does it do?

It can provision and converge a host on Azure with a recipe like the following:

### Linux

```ruby
require 'chef/provisioning/azure_driver'
with_driver 'azure'

machine_options = {
    :bootstrap_options => {
      :cloud_service_name => 'chefprovisioning', #required
      :storage_account_name => 'chefprovisioning', #required
      :vm_size => "Standard_D1", #required
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

### Windows

The following example creates a Windows Server 2012 R2 VM from the public OS image gallery, then the uses the public WinRM/s port to bootstrap the server.

```ruby
require 'chef/provisioning/azure_driver'
with_driver 'azure'

machine_options = {
    :bootstrap_options => {
      :vm_user => 'localadmin', #required if Windows
      :cloud_service_name => 'chefprovisioning', #required
      :storage_account_name => 'chefprovisioning', #required
      :vm_size => 'Standard_D1', #optional
      :location => 'West US', #optional
      :tcp_endpoints => '3389:3389', #optional
      :winrm_transport => { #optional
        'https' => { #required (valid values: 'http', 'https')
          :disable_sspi => false, #optional, (default: false)
          :basic_auth_only => false, #optional, (default: false)
          :no_ssl_peer_verification => true #optional, (default: false)
        }
      }
    },
    :password => 'P2ssw0rd', #required
    :image_id => 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201502.01-en.us-127GB.vhd' #required
}

machine 'toad' do
  machine_options machine_options
end
```

## Supported Features
 * Automatic creation and teardown of Cloud Services
 * Public (OS) images and captured User (VM) images
 * Up to date (March 2015) VM sizes including 'D', 'DS', 'G', A10/A11 sizes.
 * Custom TCP/UDP endpoints per VM role
 * Linux VMs, SSH external bootstrap via cloud service endpoint
 * Windows VMs, WinRM bootstrap via cloud service endpoint

## Currently untested/Known issues
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
 * Non-IaaS Azure services (e.g CDN/TrafficManager, Service Bus, Azure SQL Database, Media Services, Redis Cache)

Currently you have to specify the password you want the initial user to have in your recipe. No, this will not be for very long.

## Getting started

The gem is installed into Chef's default Ruby via RubyGems:

```
chef gem install chef-provisioning-azure
```

### Setting your credentials (v0.3 and above)

 * If you have previously connected to your Azure subscription using the [azure-cli](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-command-line-tools/) tools and imported your publishsettings, **you do not need to do anything else** the driver will read your profile information and certificates from ~/.azure/azureProfile.json
 * Alternatively, we support any of the methods listed in [configuration](docs/configuration.md) to set the driver up with access to your subscription
 * Note that the use of ~/.azure/config to configure the driver is **no longer supported**.

### Setting your credentials (v0.2.1 and below)

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
