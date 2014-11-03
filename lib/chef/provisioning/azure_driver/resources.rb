resources = %w()

resources.each do |r|
  Chef::Log.debug "Loading #{r}"
  require "chef/resource/azure_#{r}"
  require "chef/provider/azure_#{r}"
end
