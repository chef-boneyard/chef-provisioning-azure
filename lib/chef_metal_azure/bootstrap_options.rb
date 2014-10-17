module ChefMetalAzure
  class BootstrapOptions < ChefMetal::BootstrapOptions
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