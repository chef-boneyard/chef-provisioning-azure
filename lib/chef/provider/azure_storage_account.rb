require 'chef/provisioning/azure_driver/azure_provider'

class Chef
  class Provider
    class AzureStorageAccount < Chef::Provisioning::AzureDriver::AzureProvider
      action :create do
        Chef::Log.info("Creating AzureStorageAccount: #{new_resource.name}")
        sms = Azure::StorageManagementService.new
        sms.create_storage_account(new_resource.name, new_resource.options)
        properties = sms.get_storage_account_properties(new_resource.name)
        Chef::Log.debug("Properties of #{new_resource.name}: #{properties.inspect}")
      end

      action :destroy do
        Chef::Log.info("Destroying AzureStorageAccount: #{new_resource.name}")
        sms = Azure::StorageManagementService.new
        sms.delete_storage_account(new_resource.name)
      end
    end
  end
end
