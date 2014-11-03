require 'chef/provisioning/azure_driver'
with_driver 'azure'

machine_options = {
  bootstrap_options: {
    cloud_service_name: 'chefprovisioningtoo',
    storage_account_name: 'vmnamestorageurblc',
    #:vm_size => "A7"
    location: 'West US'
  },
  #:image_id => 'foobar'
  password: 'chefm3t4l\m/'
}

machine 'koopa' do
  machine_options machine_options
end
