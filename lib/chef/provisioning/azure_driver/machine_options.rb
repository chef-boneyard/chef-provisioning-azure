require 'chef/provisioning/machine_options'
require 'chef/provisioning/azure_driver/constants'

# Chef Provisioning Azure driver
class Chef
module Provisioning
module AzureDriver
  # Represents available machine provisioning options for Azure
  # These are used to tell Azure how to construct a new VM
  class MachineOptions < Chef::Provisioning::MachineOptions
    # @return [String] Storage account name.
    attr_accessor :storage_account_name

    # @return [String] WinRM transport mechanism ("http", or "https").
    #   Defaults to "http".
    attr_accessor :winrm_transport

    # @return [String] Cloud service name.
    attr_accessor :cloud_service_name

    # @return [String] Deployment name.
    attr_accessor :deployment_name

    # @return [Array] Array of ports to enable.
    # Can be in +port+ or +src:dest+ format.
    attr_accessor :tcp_endpoints

    # @return [Pathname] Path to the private key.
    attr_accessor :private_key_file

    # @return [Pathname] Path to the certificate file.
    attr_accessor :certificate_file

    # @return [Integer] The SSH port to listen on.
    # Defaults to 22
    attr_accessor :ssh_port

    # @return [Chef::Provisioning::AzureDriver::Constants::MachineSize] The Azure machine size.
    attr_accessor :vm_size

    # @return [String] Name of the affinity group being used.
    attr_accessor :affinity_group_name

    # @return [String] Virtual network name.
    attr_accessor :virtual_network_name

    # @return [String] Subnet name.
    attr_accessor :subnet_name

    # @return [String] Availability set name.
    attr_accessor :availability_set_name

    def initialize
      # Set defaults
      self.winrm_transport = 'http'
      self.ssh_port = 22
    end

  end
end
end
end
