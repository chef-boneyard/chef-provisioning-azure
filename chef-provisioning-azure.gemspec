$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'chef/provisioning/azure_driver/version'

Gem::Specification.new do |s|
  s.name = 'chef-provisioning-azure'
  s.version = Chef::Provisioning::AzureDriver::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = %w(README.md LICENSE)
  s.summary = 'Provisioner for creating Azure things in Chef Provisioning.'
  s.description = s.summary
  s.author = 'John Ewart'
  s.email = 'jewart@getchef.com'
  s.homepage = 'https://github.com/opscode/chef-provisioning-azure'

  s.add_dependency 'chef'
  s.add_dependency 'chef-provisioning', '~> 0.9'
  s.add_dependency 'stuartpreston-azure-sdk-for-ruby', '0.6.5'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'yard'

  s.bindir       = 'bin'
  s.executables  = %w( )

  s.require_path = 'lib'
  s.files = %w(Rakefile LICENSE README.md)
  s.files += Dir.glob('{distro,lib,tasks,spec}/**/*', File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
end
