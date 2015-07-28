require 'chef/provisioning/azure_driver/azure_provider'

class Chef
  class Provider
    class AzureCloudService < Chef::Provisioning::AzureDriver::AzureProvider
      action :create do
        Chef::Log.info("Creating AzureCloudService: #{new_resource.name}")
        csms = Azure::CloudServiceManagementService.new
        csms.create_cloud_service(new_resource.name, new_resource.options)
        properties = csms.get_cloud_service_properties(new_resource.name)
        Chef::Log.debug("Properties of #{new_resource.name}: #{properties.inspect}")
      end

      action :destroy do
        Chef::Log.info("Destroying AzureCloudService: #{new_resource.name}")
        csms = Azure::CloudServiceManagementService.new
        csms.delete_cloud_service(new_resource.name)
      end
    end
  end
end
