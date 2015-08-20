[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/chef/chef-provisioning?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# chef-provisioning-azure

This is an implementation of an Microsoft Azure driver for [chef-provisioning](/chef/chef-provisioning) that relies on [azure-sdk-for-ruby](https://github.com/stuartpreston/stuartpreston-azure-sdk-for-ruby) and the Azure Service Management API.

**Please note this driver does not support Azure Resource Manager (ARM) and is therefore only able to create "classic" VM resources that sit behind a cloud service in Azure. A new driver is under development - see [chef-provisioning-azurerm](https://github.com/pendrica/chef-provisioning-azurerm).**

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
    :image_id => 'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_2-LTS-amd64-server-20150706-en-us-30GB', #required
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
    :image_id => 'a699494373c04fc0bc8f2bb1389d6106__Windows-Server-2012-R2-201506.01-en.us-127GB.vhd' #required
}

machine 'toad' do
  machine_options machine_options
end
```

Note that images are not kept historically in Azure, therefore to find the latest images for your platform use the command ```azure vm image list``` to ensure the public image you require is available.

## Supported Features
 * Automatic creation and teardown of Cloud Services
 * Public (OS) images and captured User (VM) images
 * Up to date (March 2015) VM sizes including 'D', 'DS', 'G', A10/A11 sizes.
 * Custom TCP/UDP endpoints per VM role
 * Linux VMs, SSH external bootstrap via cloud service endpoint
 * Windows VMs, WinRM bootstrap via cloud service endpoint

## Unsupported/will not work
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

**This driver is no longer under active development as the creation of resources under Service Management mode in Azure is being deprecated in favour of Azure Resource Manager.**

## Getting started

The gem is installed into Chef's default Ruby via RubyGems:

```
chef gem install chef-provisioning-azure
```

### Setting your credentials (v0.3 and above)

 * If you have previously connected to your Azure subscription using the [azure-cli](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-command-line-tools/) tools and imported your publishSettings (by using ```azure account download``` and ```azure account import <filename.publishSettings>```), **you do not need to do anything else** the driver will read your profile information and certificates from ~/.azure/azureProfile.json
 * Alternatively, we support any of the methods listed in [configuration](docs/configuration.md) to set the driver up with access to your subscription
 * Note that the use of ~/.azure/config to configure the driver is **no longer supported**.

