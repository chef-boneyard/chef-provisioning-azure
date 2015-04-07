resources = %w(storage_account cloud_service)

resources.each do |r|
  Chef::Log.info "Loading resource: #{r}"
  require "chef/resource/azure_#{r}"
  require "chef/provider/azure_#{r}"
end
