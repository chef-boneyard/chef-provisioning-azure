class Chef
module Provisioning
module AzureDriver
  # Represents available options when bootstrapping a host on Azure
  # These are used to tell Azure some initial pieces of information
  # for building a new VM.
  class BootstrapOptions < Chef::Provisioning::BootstrapOptions
    # @return [String] The name of the VM
    attr_accessor :vm_name

    # @return [String] The VM user
    attr_accessor :vm_user

    # @return [String] The identifier for the VM image to use
    attr_accessor :image

    # @return [String] the password to use
    attr_accessor :password

    # @return [String] The Azure location to store this in
    attr_accessor :location
  end
end
end
end
