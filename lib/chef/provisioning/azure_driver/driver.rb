require 'chef/mixin/shell_out'
require 'chef/provisioning/driver'
require 'chef/provisioning/convergence_strategy/install_cached'
require 'chef/provisioning/convergence_strategy/install_sh'
require 'chef/provisioning/convergence_strategy/no_converge'
require 'chef/provisioning/transport/ssh'
require 'chef/provisioning/machine/windows_machine'
require 'chef/provisioning/machine/unix_machine'
require 'chef/provisioning/machine_spec'

require 'chef/provisioning/azure_driver/version'
require 'chef/provisioning/azure_driver/credentials'

require 'yaml'
require 'azure'

class Chef
module Provisioning
module AzureDriver
  # Provisions machines using the Azure SDK
  class Driver < Chef::Provisioning::Driver
    attr_reader :region

    # Construct an AzureDriver object from a URL - used to parse existing URL
    # data to hydrate a driver object.
    # URL scheme:
    # azure:account_id:region
    # @return [AzureDriver] A chef-provisioning Azure driver object for the given URL
    def self.from_url(driver_url, config)
      Driver.new(driver_url, config)
    end

    def initialize(driver_url, config)
      super
      # TODO: load a specific one if requested by driver config
      credentials = azure_credentials.default
      default_endpoint = 'https://management.core.windows.net'
      Azure.configure do |azure|
        # Configure these 3 properties to use Storage
        azure.management_certificate = credentials[:management_certificate]
        azure.subscription_id        = credentials[:subscription_id]
        azure.management_endpoint    = credentials[:management_endpoint] || default_endpoint
      end
    end

    # Take a URL and split it into the appropriate parts of [URL, config]
    # @return [String, Hash] A 2-element array of [URL, config]
    def self.canonicalize_url(driver_url, config)
      url = driver_url.split(':')[0]
      ["azure:#{url}", config]
    end

    # -- Machine methods --

    # Allocate a new machine with the Azure API and start it up, without
    # blocking to wait for it. Creates any needed resources to get a machine
    # up and running.
    # @param (see Chef::Provisioning::Driver#allocate_machine)
    def allocate_machine(action_handler, machine_spec, machine_options)
      existing_vm = vm_for(machine_spec)

      # We don't need to do anything if the existing VM is found
      return if existing_vm

      bootstrap_options = machine_options[:bootstrap_options] || {}
      bootstrap_options[:vm_size] ||= 'Small'
      bootstrap_options[:cloud_service_name] ||= 'chefprovisioning'
      bootstrap_options[:storage_account_name] ||=  'chefprovisioning'
      bootstrap_options[:location] ||=  'West US'

      location = bootstrap_options[:location]

      machine_spec.location = {
        'driver_url' => driver_url,
        'driver_version' => Chef::Provisioning::AzureDriver::VERSION,
        'allocated_at' => Time.now.utc.to_s,
        'host_node' => action_handler.host_node,
        'image_id' => machine_options[:image_id],
        'location' => location,
        'cloud_service' => bootstrap_options[:cloud_service_name]
      }

      image_id = machine_options[:image_id] || default_image_for_location(location)

      Chef::Log.debug "Azure bootstrap options: #{bootstrap_options.inspect}"
      
      # If the cloud service exists already, need to add a role to it - otherwise create virtual machine (including cloud service)
      cloud_service = azure_cloud_service_service.get_cloud_service(bootstrap_options[:cloud_service_name])

      if cloud_service
        action_handler.report_progress "Cloud Service #{bootstrap_options[:cloud_service_name]} already exists, adding role."
        params = {
          vm_name: machine_spec.name,
          vm_user: default_ssh_username,
          image: image_id,
          # This is only until SSH keys are added
          password: machine_options[:password],
          cloud_service_name: bootstrap_options[:cloud_service_name]
        }

        action_handler.report_progress "Creating #{machine_spec.name} with image #{image_id} in #{bootstrap_options[:cloud_service_name]}..."
        vm = azure_vm_service.add_role(params, bootstrap_options)
      else
        params = {
          vm_name: machine_spec.name,
          vm_user: default_ssh_username,
          image: image_id,
          # This is only until SSH keys are added
          password: machine_options[:password],
          location: location
        }

        action_handler.report_progress "Creating #{machine_spec.name} with image #{image_id} in #{location}..."
        vm = azure_vm_service.create_virtual_machine(params, bootstrap_options)
      end

      machine_spec.location['vm_name'] = vm.vm_name
      action_handler.report_progress "Created #{vm.vm_name} in #{location}..."      
    end

    # (see Chef::Provisioning::Driver#ready_machine)
    def ready_machine(action_handler, machine_spec, machine_options)
      vm = vm_for(machine_spec)
      location = machine_spec.location['location']

      if vm.nil?
        fail "Machine #{machine_spec.name} does not have a VM associated with it, or the VM does not exist."
      end

      # TODO: Not sure if this is the right thing to check
      if vm.status != 'ReadyRole'
        action_handler.report_progress "Readying #{machine_spec.name} in #{location}..."
        wait_until_ready(action_handler, machine_spec)
        wait_for_transport(action_handler, machine_spec, machine_options)
      else
        action_handler.report_progress "#{machine_spec.name} already ready in #{location}!"
      end

      machine_for(machine_spec, machine_options, vm)
    end

    # (see Chef::Provisioning::Driver#destroy_machine)
    def destroy_machine(action_handler, machine_spec, machine_options)
      vm = vm_for(machine_spec)
      vm_name = machine_spec.name
      cloud_service = machine_spec.location['cloud_service']

      # Check if we need to proceed
      return if vm.nil? || vm_name.nil? || cloud_service.nil?

      # Skip if we don't actually need to do anything
      return unless action_handler.should_perform_actions

      # TODO: action_handler.do |block| ?
      action_handler.report_progress "Destroying VM #{machine_spec.name}!"
      azure_vm_service.delete_virtual_machine(vm_name, cloud_service)
      action_handler.report_progress "Destroyed VM #{machine_spec.name}!"
    end

    private

    def machine_for(machine_spec, machine_options, vm = nil)
      vm ||= vm_for(machine_spec)

      fail "VM for node #{machine_spec.name} has not been created!" unless vm

      transport =  transport_for(machine_spec, machine_options, vm)
      convergence_strategy = convergence_strategy_for(machine_spec, machine_options)

      if machine_spec.location['is_windows']
        Chef::Provisioning::Machine::WindowsMachine.new(machine_spec, transport, convergence_strategy)
      else
        Chef::Provisioning::Machine::UnixMachine.new(machine_spec, transport, convergence_strategy)
      end
    end

    def azure_vm_service
      @vm_service ||= Azure::VirtualMachineManagementService.new
    end

    def azure_cloud_service_service
      @cloud_service_service ||= Azure::CloudServiceManagementService.new
    end

    def default_ssh_username
      'ubuntu'
    end

    def vm_for(machine_spec)
      if machine_spec.location && machine_spec.name
        existing_vms = azure_vm_service.list_virtual_machines
        existing_vms.select { |vm| vm.vm_name == machine_spec.name }.first
      else
        nil
      end
    end

    def transport_for(machine_spec, machine_options, vm)
      # TODO winrm
      create_ssh_transport(machine_spec, machine_options, vm)
    end

    def azure_credentials
      # Grab the list of possible credentials
      @azure_credentials ||= if driver_options[:azure_credentials]
                               driver_options[:azure_credentials]
                             else
                               credentials = Credentials.new
                               if driver_options[:azure_config_file]
                                 credentials.load_ini(driver_options.delete(:azure_config_file))
                               else
                                 credentials.load_default
                               end
                               credentials
                             end
    end

    def default_image_for_location(location)
      Chef::Log.debug("Choosing default image for region '#{location}'")

      case location
      when 'East US'
      when 'Southeast Asia'
      when 'West US'
        'b39f27a8b8c64d52b05eac6a62ebad85__Ubuntu-14_04_1-LTS-amd64-server-20140927-en-us-30GB'
      else
        raise 'Unsupported location!'
      end
    end

    def create_ssh_transport(machine_spec, machine_options, vm)
      username = machine_spec.location['ssh_username'] || default_ssh_username
      tcp_endpoint = vm.tcp_endpoints.select { |tcp| tcp[:name] == 'SSH' }.first
      remote_host = tcp_endpoint[:vip]

      # TODO: not this... replace with SSH key ASAP, only for getting this thing going...
      ssh_options = { 
        password: machine_options[:password],
        port: tcp_endpoint[:public_port] # use public port from Cloud Service endpoint
      }

      options = {}
      options[:prefix] = 'sudo ' if machine_spec.location[:sudo] || username != 'root'

      # Enable pty by default
      # TODO: why?
      options[:ssh_pty_enable] = true
      options[:ssh_gateway] ||= machine_spec.location['ssh_gateway']

      Chef::Provisioning::Transport::SSH.new(remote_host, username, ssh_options, options, config)
    end

    def convergence_strategy_for(machine_spec, machine_options)
      convergence_options = machine_options[:convergence_options]
      # Defaults
      unless machine_spec.location
        return Chef::Provisioning::ConvergenceStrategy::NoConverge.new(convergence_options, config)
      end

      if machine_spec.location['is_windows']
        Chef::Provisioning::ConvergenceStrategy::InstallMsi.new(convergence_options, config)
      elsif machine_options[:cached_installer]
        Chef::Provisioning::ConvergenceStrategy::InstallCached.new(convergence_options, config)
      else
        Chef::Provisioning::ConvergenceStrategy::InstallSh.new(convergence_options, config)
      end
    end

    def wait_until_ready(action_handler, machine_spec)
      vm = vm_for(machine_spec)

      # If the machine is ready, nothing to do
      return if vm.status == 'ReadyRole'

      # Skip if we don't actually need to do anything
      return unless action_handler.should_perform_actions

      time_elapsed = 0
      sleep_time = 10
      max_wait_time = 120

      action_handler.report_progress "waiting for #{machine_spec.name} to be ready ..."
      while time_elapsed < 120 && vm.status != 'ReadyRole'
        action_handler.report_progress "#{time_elapsed}/#{max_wait_time}s..."
        sleep(sleep_time)
        time_elapsed += sleep_time
        # Azure caches results
        vm = vm_for(machine_spec)
      end
      action_handler.report_progress "#{machine_spec.name} is now ready"
    end

    def wait_for_transport(action_handler, machine_spec, machine_options)
      vm = vm_for(machine_spec)
      transport = transport_for(machine_spec, machine_options, vm)

      return if transport.available?
      return unless action_handler.should_perform_actions

      time_elapsed = 0
      sleep_time = 10
      max_wait_time = 120

      action_handler.report_progress "Waiting for transport on #{machine_spec.name} ..."
      while time_elapsed < 120 && !transport.available?
        action_handler.report_progress "#{time_elapsed}/#{max_wait_time}s..."
        sleep(sleep_time)
        time_elapsed += sleep_time
      end
      action_handler.report_progress "Transport to #{machine_spec.name} is now up!"
    end

  end
end
end
end
