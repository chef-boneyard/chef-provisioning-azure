require 'chef/resource/lwrp_base'
require 'chef/provisioning/azure_driver/subscriptions'

class Chef
  module Provisioning
    module AzureDriver
      class AzureResource < Chef::Resource::LWRPBase
        def initialize(*args)
          super
          if run_context
            @chef_environment = run_context.cheffish.current_environment
            @chef_server = run_context.cheffish.current_chef_server
            @driver = run_context.chef_provisioning.current_driver
          end

          config = run_context.chef_provisioning.config
          scheme, account_id = driver.split(':', 2)

          if account_id.nil? || account_id.empty?
            subscription = Subscriptions.default_subscription(config)
            config = Cheffish::MergedConfig.new({ azure_subscriptions: subscription }, config)
            if !subscription
              raise "Driver #{driver} did not specify a subscription ID, and no default subscription was found.  Have you downloaded the Azure CLI and used `azure account download` and `azure account import` to set up Azure?  Alternately, you can set azure_subscriptions to [ { subscription_id: '...', management_credentials: ... }] in your Chef configuration."
            end
          else
            subscription_id = account_id || subscription[:subscription_id]
            subscription = Subscriptions.get_subscription(config, subscription_id)
          end

          if !subscription
            raise "Driver #{driver} has a subscription ID (#{subscription_id}), but the system has no credentials configured for it!  If you have access to this subscription, you can use `azure account download` and `azure account import` in the Azure CLI to get the credentials, or set azure_subscriptions to [ { subscription_id: '...', management_credentials: ... }] in your Chef configuration."
          else
            Chef::Log.debug("Using subscription: #{subscription.inspect}")
          end

          Azure.configure do |azure|
            azure.management_certificate = subscription[:management_certificate]
            azure.subscription_id        = subscription[:subscription_id]
            azure.management_endpoint    = subscription[:management_endpoint]
          end
        end

        attribute :driver
        attribute :chef_server, kind_of: Hash
        attribute :managed_entry_store, kind_of: Chef::Provisioning::ManagedEntryStore,
                                  lazy_default: proc { Chef::Provisioning::ChefManagedEntryStore.new(chef_server) }
        attribute :subscription
      end
    end
  end
end
