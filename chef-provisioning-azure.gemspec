$LOAD_PATH.unshift(File.dirname(__FILE__) + '/lib')
require 'chef/provisioning/azure_driver/version'

Gem::Specification.new do |s|
  s.name = 'chef-provisioning-azure'
  s.version = Chef::Provisioning::AzureDriver::VERSION
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = %w(README.md LICENSE)
  s.summary = 'Provisioner for creating Microsoft Azure resources using ' \
    'Chef Provisioning.'
  s.description = 'This is a driver that works with chef-provisioning that ' \
    'allows Chef Provisioning to manage objects in Microsoft Azure.'
  s.author = 'John Ewart'
  s.email = 'jewart@getchef.com'
  s.homepage = 'https://github.com/chef/chef-provisioning-azure'
  s.license = 'Apache-2.0'

  s.add_dependency 'chef-provisioning', '~> 1.0'
  s.add_dependency 'stuartpreston-azure-sdk-for-ruby', '~> 0.7'

  s.add_development_dependency 'chef', '>= 12.0'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'github_changelog_generator'

  s.bindir       = 'bin'
  s.executables  = %w( )

  s.require_path = 'lib'
  s.files = %w(Gemfile Rakefile LICENSE README.md) + Dir.glob('*.gemspec')
  s.files += Dir.glob('{distro,lib,tasks,spec}/**/*', File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
end
