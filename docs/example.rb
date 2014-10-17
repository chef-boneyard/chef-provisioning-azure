require 'chef_metal_azure'
with_driver 'azure'

machine_options = {
    :bootstrap_options => {
      :cloud_service_name => 'chefmetal',
      :storage_account_name => 'chefmetal',
      #:vm_size => "A7"
      :location => 'West US'
    },
    #:image_id => 'foobar'
    :password => "chefm3t4l\\m/"
}

machine 'toad' do
  machine_options machine_options
end

  