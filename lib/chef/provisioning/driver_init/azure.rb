require 'chef/provisioning/azure_driver/driver'

Chef::Provisioning.register_driver_class('azure', Chef::Provisioning::AzureDriver::Driver)
