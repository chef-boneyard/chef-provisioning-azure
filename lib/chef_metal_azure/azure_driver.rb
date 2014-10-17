require 'chef/mixin/shell_out'
require 'chef_metal/driver'
require 'chef_metal/convergence_strategy/install_cached'
require 'chef_metal/convergence_strategy/install_sh'
require 'chef_metal/convergence_strategy/no_converge'
require 'chef_metal/transport/ssh'
require 'chef_metal/machine/windows_machine'
require 'chef_metal/machine/unix_machine'
require 'chef_metal/machine_spec'

require 'chef_metal_azure/version'
require 'chef_metal_azure/credentials'

require 'yaml'
require 'azure'


module ChefMetalAzure
  # Provisions machines using the Azure SDK
  class AzureDriver < ChefMetal::Driver

    attr_reader :region

    # Construct an AzureDriver object from a URL - used to parse existing URL
    # data to hydrate a driver object.
    # URL scheme:
    # azure:account_id:region
    # @return [AzureDriver] A chef-metal Azure driver object for the given URL
    def self.from_url(driver_url, config)
      AzureDriver.new(driver_url, config)
    end

    def initialize(driver_url, config)
      super
      # TODO - load a specific one if requested
      credentials = azure_credentials.default
      Azure.configure do |azure|
        # Configure these 3 properties to use Storage
        azure.management_certificate = credentials[:management_certificate]
        azure.subscription_id        = credentials[:subscription_id]
        azure.management_endpoint    = credentials[:management_endpoint] || 'https://management.core.windows.net'
      end
    end

    # Take a URL and split it into the appropriate parts of [URL, config]
    # @return [String, Hash] A 2-element array of [URL, config]
    def self.canonicalize_url(driver_url, config)
      url = driver_url.split(":")[0]
      [ "azure:#{url}", config ]
    end


    # (see ChefMetal::Driver#allocate_image)
    def allocate_image(action_handler, image_spec, image_options, machine_spec)
    end

    # (see ChefMetal::Driver#ready_image)
    def ready_image(action_handler, image_spec, image_options)
    end

    # (see ChefMetal::Driver#destroy_image)
    def destroy_image(action_handler, image_spec, image_options)
    end

    # Machine methods

    # Allocate a new machine with the Azure API and start it up, without
    # blocking to wait for it. Creates any needed resources to get a machine
    # up and running.
    # @param (see ChefMetal::Driver#allocate_machine)
    def allocate_machine(action_handler, machine_spec, machine_options)
      existing_vm = vm_for(machine_spec)
      if existing_vm == nil

        bootstrap_options = machine_options[:bootstrap_options] || {}
        bootstrap_options[:vm_size] ||= 'Small'
        bootstrap_options[:cloud_service_name] ||= 'chefmetal'
        bootstrap_options[:storage_account_name] ||=  'chefmetal'
        bootstrap_options[:location] ||=  'West US'

        location = bootstrap_options[:location]

        machine_spec.location = {
            'driver_url' => driver_url,
            'driver_version' => ChefMetalAzure::VERSION,
            'allocated_at' => Time.now.utc.to_s,
            'host_node' => action_handler.host_node,
            'image_id' => machine_options[:image_id],
            'location' => location
        }

        image_id = machine_options[:image_id] || default_image_for_location(location)

        params = {
            :vm_name  => machine_spec.name,
            :vm_user  => default_ssh_username,
            :image    => image_id,
            # This is only until SSH keys are added
            :password => machine_options[:password],
            :location => location
        }

        Chef::Log.debug "Azure bootstrap options: #{bootstrap_options.inspect}"

        action_handler.report_progress "Creating #{machine_spec.name} with image #{image_id} in #{location}..."
        vm = azure_vm_service.create_virtual_machine(params, bootstrap_options)
        machine_spec.location['vm_name'] = vm.vm_name
        action_handler.report_progress "Created #{vm.vm_name} in #{location}..."
      end
    end

    # (see ChefMetal::Driver#ready_machine)
    def ready_machine(action_handler, machine_spec, machine_options)
      vm = vm_for(machine_spec)

      if vm.nil?
        raise "Machine #{machine_spec.name} does not have a VM associated with it, or the VM does not exist."
      end

      # TODO: Not sure if this is the right thing to check
      if vm.status != 'ReadyRole'
        action_handler.report_progress "Readying #{machine_spec.name} in #{machine_spec.location['location']}..."
        wait_until_ready(action_handler, machine_spec)
        wait_for_transport(action_handler, machine_spec, machine_options)
      else
        action_handler.report_progress "#{machine_spec.name} (#{machine_spec.location['location']}) already running in #{@region}..."
      end

      machine_for(machine_spec, machine_options, vm)

    end

    # (see ChefMetal::Driver#destroy_machine)
    def destroy_machine(action_handler, machine_spec, machine_options)
      vm = vm_for(machine_spec)
      if vm
        vm.terminate
      end
    end


    private
    def machine_for(machine_spec, machine_options, vm = nil)
      vm ||= vm_for(machine_spec)

      if !vm
        raise "VM for node #{machine_spec.name} has not been created!"
      end

      if machine_spec.location['is_windows']
        ChefMetal::Machine::WindowsMachine.new(machine_spec, transport_for(machine_spec, machine_options, vm), convergence_strategy_for(machine_spec, machine_options))
      else
        ChefMetal::Machine::UnixMachine.new(machine_spec, transport_for(machine_spec, machine_options, vm), convergence_strategy_for(machine_spec, machine_options))
      end
    end

    def start_machine(action_handler, machine_spec, machine_options, base_image_name)
    end

    def azure_vm_service
      @vm_service ||= Azure::VirtualMachineManagementService.new
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

      #TODO: not this... replace with SSH key ASAP, only for getting this thing going...
      ssh_options = { :password => machine_options[:password] }
      options = {}
      if machine_spec.location[:sudo] || (!machine_spec.location.has_key?(:sudo) && username != 'root')
        options[:prefix] = 'sudo '
      end

      #Enable pty by default
      options[:ssh_pty_enable] = true
      options[:ssh_gateway] = machine_spec.location['ssh_gateway'] if machine_spec.location.has_key?('ssh_gateway')

      ChefMetal::Transport::SSH.new(remote_host, username, ssh_options, options, config)
    end

    def convergence_strategy_for(machine_spec, machine_options)
      # Defaults
      if !machine_spec.location
        return ChefMetal::ConvergenceStrategy::NoConverge.new(machine_options[:convergence_options], config)
      end

      if machine_spec.location['is_windows']
        ChefMetal::ConvergenceStrategy::InstallMsi.new(machine_options[:convergence_options], config)
      elsif machine_options[:cached_installer] == true
        ChefMetal::ConvergenceStrategy::InstallCached.new(machine_options[:convergence_options], config)
      else
        ChefMetal::ConvergenceStrategy::InstallSh.new(machine_options[:convergence_options], config)
      end
    end

    def wait_until_ready(action_handler, machine_spec)
      vm = vm_for(machine_spec)
      time_elapsed = 0
      sleep_time = 10
      max_wait_time = 120
      unless vm.status == 'ReadyRole'
        if action_handler.should_perform_actions
          action_handler.report_progress "waiting for #{machine_spec.name} (#{driver_url}) to be ready ..."
          while time_elapsed < 120 && vm.status != 'ReadyRole'
            action_handler.report_progress "been waiting #{time_elapsed}/#{max_wait_time} -- sleeping #{sleep_time} seconds for #{machine_spec.name} (#{driver_url}) to be ready ..."
            sleep(sleep_time)
            time_elapsed += sleep_time
            # Azure caches results
            vm = vm_for(machine_spec)
          end
          action_handler.report_progress "#{machine_spec.name} is now ready"
        end
      end
    end

    def wait_for_transport(action_handler, machine_spec, machine_options)
      vm = vm_for(machine_spec)
      time_elapsed = 0
      sleep_time = 10
      max_wait_time = 120
      transport = transport_for(machine_spec, machine_options, vm)
      unless transport.available?
        if action_handler.should_perform_actions
          action_handler.report_progress "waiting for #{machine_spec.name} (#{driver_url}) to be connectable (transport up and running) ..."
          while time_elapsed < 120 && !transport.available?
            action_handler.report_progress "been waiting #{time_elapsed}/#{max_wait_time} -- sleeping #{sleep_time} seconds for #{machine_spec.name} (#{vm.id} on #{driver_url}) to be connectable ..."
            sleep(sleep_time)
            time_elapsed += sleep_time
            # Azure caches results
            vm = vm_for(machine_spec)
          end

          action_handler.report_progress "#{machine_spec.name} is now connectable"
        end
      end
    end

  end
end
