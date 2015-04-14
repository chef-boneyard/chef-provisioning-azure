require 'inifile'
require 'json'
require 'nokogiri'

class Chef
module Provisioning
module AzureDriver
module Subscriptions

  #
  # Get the subscription with the given subscription_id or subscription_name
  #
  # Returns `nil` if nothing found.
  #
  def self.get_subscription(config, subscription_id_or_name)
    subscription_count = 0
    subscription = all_subscriptions(config).select do |s|
      subscription_count += 1
      s[:subscription_id]   == subscription_id_or_name ||
      s[:subscription_name] == subscription_id_or_name
    end.first
    if !subscription
      Chef::Log.info("Subscription #{subscription_id_or_name} not found out of #{subscription_count} subscriptions read.")
    end
    subscription
  end

  #
  # Get the default subscription for the given config.
  #
  # The default subscription is either the first .azureProfile subscription with isDefault: true
  #
  def self.default_subscription(config)
    first_subscription = nil
    all_subscriptions(config).each do |subscription|
      if subscription[:is_default]
        Chef::Log.info("Picked default subscription: #{subscription[:subscription_name]} (#{subscription[:subscription_id]}) from #{subscription[:source]}")
        return subscription
      end

      first_subscription ||= subscription;
    end
    if first_subscription
      Chef::Log.info("Picked first subscription found as default: #{first_subscription[:subscription_name]} (#{first_subscription[:subscription_id]}) from #{first_subscription[:source]}")
    else
      Chef::Log.info("No subscriptions found.")
    end
    first_subscription
  end

  #
  # We search for subscription in the order specified by Chef::Config.azure_subscriptions,
  # which includes:
  #
  # Key                           | Description
  # ------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------
  # `subscription_id`             | The GUID of the subscription.
  # `subscription_name`           | The name of the subscription.
  # `management_certificate`      | The path to the actual credentials, a proc, or an IO object (optional; if this is not set, the keychain will be searched).
  # `management_endpoint`         | The management endpoint URL (optional; if not set, the default Azure endpoint will be used).
  # `is_default`                  | If `true`, this should be considered the default subscription.
  # `publishsettings`             | The path/glob to one or more `.publishsettings` formatted files, an IO object, or a hash with one or more { type: <path|io> } keys, where type=:pem, :pdx or :cert.
  # `azure_profile`               | The path/glob to one or more `azureProfile.json` formatted files, an IO object, or a Hash representing the parsed data.
  # `allow_missing_file`          | If `true`, provisioning will skip the publishsettings or azure_profile if it does not exist; otherwise it will raise an error on missing file.  Defaults to `false`.
  #
  def self.all_subscriptions(config)
    Enumerator.new do |y|
      subscriptions = config[:azure_subscriptions]
      subscriptions ||= default_subscriptions(config)
      subscriptions = [ subscriptions ].flatten

      subscriptions.each do |subscription_spec|
        allow_missing_file = subscription_spec[:allow_missing_file]
        if subscription_spec[:subscription_id]
          subscription = {
            management_endpoint: default_management_endpoint(config),
            source:              "Chef configuration"
          }
          y.yield subscription.merge(subscription_spec)
        end
        if subscription_spec[:publishsettings]
          load_publishsettings_subscriptions(config, subscription_spec[:publishsettings], allow_missing_file) do |subscription|
            y.yield subscription.merge(subscription_spec)
          end
        end
        if subscription_spec[:azure_profile]
          load_azure_profile_subscriptions(config, subscription_spec[:azure_profile], allow_missing_file) do |subscription|
            y.yield subscription.merge(subscription_spec)
          end
        end
      end
    end
  end

  def self.load_publishsettings_subscriptions(config, data, allow_missing_file, filename=nil, &block)
    case data
    when String
      found = false
      Dir.glob(data) do |filename|
        found = true
        Chef::Log.info("Reading publishsettings file #{filename}")
        File.open(filename) do |f|
          load_publishsettings_subscriptions(config, f, allow_missing_file, filename, &block)
        end
      end
      if !found
        if allow_missing_file
          Chef::Log.info("Skipping missing publishsettings file #{data}.")
        else
          raise "Missing publishsettings file #{data}!"
        end
      end

    when IO
      xml = Nokogiri::XML(data)

      # Parse publishsettings content
      xml.xpath("//PublishData/PublishProfile/Subscription").each do |subscription|
        Chef::Log.debug("- Read subscription #{subscription['Name']} (#{subscription['Id']})")
        result = {
          subscription_id:        subscription['Id'],
          subscription_name:      subscription['Name'],
          management_endpoint:    subscription['ServiceManagementUrl'] || default_management_endpoint(config),
          source:                 "publishsettings #{filename ? "file #{filename}" : " IO object"}"
        }
        result[:publishsettings] = filename if filename
        if subscription['ManagementCertificate']
          result[:management_certificate] = {
            type: :pdx,
            data: subscription['ManagementCertificate']
          }
        end
        yield result
      end
    else
      raise "Unexpected value #{data.inspect} for publishsettings!"
    end
  end

  def self.load_azure_profile_subscriptions(config, data, allow_missing_file, filename=nil, &block)
    case data
    when String
      found = false
      Dir.glob(data) do |filename|
        found = true
        Chef::Log.info("Reading azure profile file #{filename}")
        File.open(filename) do |f|
          load_azure_profile_subscriptions(config, f, allow_missing_file, filename, &block)
        end
      end
      if !found
        if allow_missing_file
          Chef::Log.info("Skipping missing azure profile file #{data}.")
        else
          raise "Missing azure profile file #{data}!"
        end
      end

    when IO
      profile = JSON.parse(data.read, create_additions: false)
      if profile["subscriptions"]
        profile["subscriptions"].each do |subscription|
          Chef::Log.debug("- Read#{subscription['isDefault'] ? " default" : ""} subscription #{subscription['name']} (#{subscription['id']})")

          result = {
            subscription_id:     subscription['id'],
            subscription_name:   subscription['name'],
            management_endpoint: subscription['managementEndpointUrl'] || default_management_endpoint(config),
            source:                 "azure profile #{filename ? "file #{filename}" : " IO object"}"
          }
          subscription[:azure_profile] = filename
          if subscription['isDefault']
            result[:is_default] = true
          end
          if subscription['managementCertificate'] && subscription['managementCertificate']['key']
            # Concatenate the key and cert to one .pem so the SDK will be OK with it
            result[:management_certificate] = {
              type: :pem,
              data: "#{subscription['managementCertificate']['key']}#{subscription['managementCertificate']['cert']}",
            }
          end
          yield result
        end
      else
        Chef::Log.warn("Azure profile #{filename ? "file #{filename}" : data} has no subscriptions")
      end

    else
      raise "Unexpected value #{data.inspect} for azure_profile!"
    end
  end

  def self.default_subscriptions(config)
    default_azure_profile = self.default_azure_profile(config)
    azure_publish_settings_file = Chef::Config.knife[:azure_publish_settings_file] if Chef::Config.knife
    Chef::Log.debug("No Chef::Config[:driver_options][:subscriptions] found, reading environment variables AZURE_SUBSCRIPTION_ID, AZURE_MANAGEMENT_CERTIFICATE, and AZURE_MANAGEMENT_ENDPOINT,#{azure_publish_settings_file ? " then #{azure_publish_settings_file}," : ""} and then reading #{default_azure_profile}")
    result = []
    result << {
      subscription_id:        ENV["AZURE_SUBSCRIPTION_ID"],
      management_certificate: ENV["AZURE_MANAGEMENT_CERTIFICATE"],
      management_endpoint:    ENV["AZURE_MANAGEMENT_ENDPOINT"],
      source:                 "environment variables"
    }
    result << { publishsettings: azure_publish_settings_file } if azure_publish_settings_file
    result << {
      azure_profile: default_azure_profile,
      allow_missing_file: true
    }
    result
  end

  def self.default_management_endpoint(config)
    'https://management.core.windows.net'
  end

  def self.default_azure_profile(config)
    File.join(config[:home_dir] || File.expand_path("~"), ".azure", "azureProfile.json")
  end
end
end
end
end
