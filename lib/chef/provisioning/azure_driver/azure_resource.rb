require 'chef/resource/lwrp_base'
require 'chef/provisioning/azure_driver/subscriptions'

class Chef
  module Provisioning
    module AzureDriver
      class AzureResource < Chef::Resource::LWRPBase
        def initialize(*args)
          super
          @chef_environment = run_context.cheffish.current_environment
          @chef_server = run_context.cheffish.current_chef_server
          @driver = run_context.chef_provisioning.current_driver

          config = run_context.chef_provisioning.config
          scheme, account_id = driver.split(':', 2)

          if account_id.nil? || account_id.empty?
            subscription = Subscriptions.default_subscription(config)
            if !subscription
              raise "Driver #{driver_url} did not specify a subscription ID, and no default subscription was found.  Have you downloaded the Azure CLI and used `azure account download` and `azure account import` to set up Azure?  Alternately, you can set azure_subscriptions to [ { subscription_id: '...', management_credentials: ... }] in your Chef configuration."
            end
          end

          config = Cheffish::MergedConfig.new({ azure_subscriptions: subscription }, config)
          scheme, subscription_id = driver.split(':', 2)
          @subscription = Subscriptions.get_subscription(config, subscription_id)
          if !subscription
            raise "Driver #{driver_url} has a subscription ID, but the system has no credentials configured for it!  If you have access to this subscription, you can use `azure account download` and `azure account import` in the Azure CLI to get the credentials, or set azure_subscriptions to [ { subscription_id: '...', management_credentials: ... }] in your Chef configuration."
          end

          Azure.configure do |azure|
            azure.management_certificate = subscription[:management_certificate]
            azure.subscription_id        = subscription[:subscription_id]
            azure.management_endpoint    = subscription[:management_endpoint]
          end
        end

        attr_accessor :driver
        attr_accessor :subscription
      end
    end
  end
end
