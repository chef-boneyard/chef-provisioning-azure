require 'chef/provisioning/azure_driver/azure_provider'

class Chef
  class Provider
    class AzureSqlServer < Chef::Provisioning::AzureDriver::AzureProvider
      action :create do
        restore = Azure.config.management_endpoint
        Azure.config.management_endpoint = azure_sql_management_endpoint
        Chef::Log.info("Creating AzureSqlServer: #{new_resource.name}")
        csql = Azure::SqlDatabaseManagementService.new
        Chef::Log.info("#{new_resource.options.inspect}")
        properties = csql.create_server("#{new_resource.options[:login]}", \
                                        "#{new_resource.options[:password]}", \
                                        "#{new_resource.options[:location]}")
        server = properties.name

        new_resource.options[:firewall_rules].each do | rule |
          rule_name = URI::encode(rule[:name])
          range = {
            :start_ip_address => rule[:start_ip_address],
            :end_ip_address => rule[:end_ip_address]
          }
          csql.set_sql_server_firewall_rule(server, rule_name, range)
        end

        Chef::Log.info("Properties of #{new_resource.name}: #{properties.inspect}")
        Azure.config.management_endpoint = restore
      end

      action :destroy do
        # not supported
        fail "Destroy not yet implemented on Azure SQL Server using ASM."
      end
    end
  end
end
