require 'chef/provider/lwrp_base'
require 'chef/provisioning/azure_driver/azure_resource'
require 'chef/provisioning/chef_provider_action_handler'
require 'azure'

class Chef
  module Provisioning
    module AzureDriver
      class AzureProvider < Chef::Provider::LWRPBase
        use_inline_resources

        AzureResource = Chef::Provisioning::AzureDriver::AzureResource

        def azure_sql_management_endpoint
          'https://management.database.windows.net:8443'
        end

        def action_handler
          @action_handler ||= Chef::Provisioning::ChefProviderActionHandler.new(self)
        end

        # All these need to implement whyrun
        def whyrun_supported?
          true
        end

        def driver
          new_resource.driver
        end
      end
    end
  end
end
