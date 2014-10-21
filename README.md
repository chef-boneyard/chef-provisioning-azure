[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/opscode/chef-metal?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# chef-metal-azure

Implementation of an Azure driver that relies on the Azure SDK. 

This is not quite ready for public consumption and is under active
development.


## DO NOT USE THIS FOR ANYTHING IMPORTANT

At least not yet, you have been warned :grin:


## What does it do?

It can provision and converge a host on Azure with a recipe like the following:

```ruby
require 'chef_metal_azure'
with_driver 'azure'

machine_options = {
    :bootstrap_options => {
      :cloud_service_name => 'chefmetal',
      :storage_account_name => 'chefmetal',
      #:vm_size => "A7"
      :location => 'West US'
    },
    #:image_id => 'foobar'
    # Until SSH keys are supported (soon)
    :password => "chefm3t4l\\m/"
}

machine 'toad' do
  machine_options machine_options
end
```
 
That's it. No images, nothing else. Do not expect much just yet. Currently you have to specify the 
password you want the initial user to have in your recipe. No, this will not be for very long. 

### Setting your credentials

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
