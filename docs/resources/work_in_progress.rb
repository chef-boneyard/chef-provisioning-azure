require "chef/provisioning/azure_driver"
with_driver "azure"

# NOTE: THESE ARE ASPIRATIONAL RESOURCES, SUBJECT TO CHANGE
# THEY ALSO DO NOT STORE A MANAGEDENTRY IN CHEF SERVER
# USE ONLY TO CREATE UNMANAGED RESOURCES IN AZURE
#
# USE AT OWN RISK!!

## Auxiliary resources

azure_storage_account "spteststorage41" do
  action :create
  options :location => "West US",
          :geo_replication_enabled => false
end

azure_cloud_service "sptestcloud41" do
  action :create
  options :location => "West US"
end

## PAAS resources

# note: azure_sql_server does not accept being provided a name until APIv2 (RM)
# Azure will autogenerate a name, we should store this I guess so it can be used
# later on...
azure_sql_server "sptestsql41" do
  action :create
  options :location => "West US",
          :login => "sqluser",
          :password => "P2ssw0rd",
          :firewall_rules => [
            {
              :name => "rule 1",
              :start_ip_address => "10.0.0.1",
              :end_ip_address => "10.0.0.2",
            },
            {
              :name => "rule 2",
              :start_ip_address => "10.1.0.1",
              :end_ip_address => "10.1.0.2",
            },
          ]
end

## NOT WORKING - DO NOT USE
#azure_service_bus_queue 'sptestqueue01' do
#  action :create
#  namespace 'mynamespace'
#  options :max_size_in_megabytes => 2048
#end
