# Change Log

## [0.4.0](https://github.com/chef/chef-provisioning-azure/tree/0.4.0) (2016-02-03)
[Full Changelog](https://github.com/chef/chef-provisioning-azure/compare/v0.4.0...0.4.0)

**Merged pull requests:**

- Add gemspec files to allow bundler to run from the gem [\#41](https://github.com/chef/chef-provisioning-azure/pull/41) ([ksubrama](https://github.com/ksubrama))

## [v0.4.0](https://github.com/chef/chef-provisioning-azure/tree/v0.4.0) (2015-09-16)
[Full Changelog](https://github.com/chef/chef-provisioning-azure/compare/v0.3.3...v0.4.0)

**Closed issues:**

- :vm\_user won't work, it requres ubuntu\(default\) user. [\#39](https://github.com/chef/chef-provisioning-azure/issues/39)

**Merged pull requests:**

- Make chef a development dependency. [\#40](https://github.com/chef/chef-provisioning-azure/pull/40) ([ksubrama](https://github.com/ksubrama))

## [v0.3.3](https://github.com/chef/chef-provisioning-azure/tree/v0.3.3) (2015-09-10)
[Full Changelog](https://github.com/chef/chef-provisioning-azure/compare/v0.3.2...v0.3.3)

**Fixed bugs:**

- Specification of storage account should be optional [\#27](https://github.com/chef/chef-provisioning-azure/issues/27)

**Closed issues:**

- What is the default username that is created when we provision Linux VM? [\#36](https://github.com/chef/chef-provisioning-azure/issues/36)
- error: You did not provide a valid 'private\_key\_file, certificate\_file' value. [\#33](https://github.com/chef/chef-provisioning-azure/issues/33)
- vm name cannot have dots in it [\#32](https://github.com/chef/chef-provisioning-azure/issues/32)
-  no implicit conversion of nil into String [\#30](https://github.com/chef/chef-provisioning-azure/issues/30)
- Unable to create a Centos linux machine [\#29](https://github.com/chef/chef-provisioning-azure/issues/29)
- Localadmin user name for Windows systems is not configurable [\#28](https://github.com/chef/chef-provisioning-azure/issues/28)
- Guest agent is not provisioned [\#26](https://github.com/chef/chef-provisioning-azure/issues/26)
- :tcp\_endpoint is not idempotent [\#23](https://github.com/chef/chef-provisioning-azure/issues/23)
- Chef::Provisioning::AzureDriver::Driver does not implement connect\_to\_machine [\#21](https://github.com/chef/chef-provisioning-azure/issues/21)
- chef-provisioning-azure does not capture public ip of created instances [\#20](https://github.com/chef/chef-provisioning-azure/issues/20)
- add\_machine\_options fails on azure [\#19](https://github.com/chef/chef-provisioning-azure/issues/19)
- NoMethodError: undefined method `vm\_name' [\#18](https://github.com/chef/chef-provisioning-azure/issues/18)
- Support for .publishsettings file for credentials [\#16](https://github.com/chef/chef-provisioning-azure/issues/16)
- Timeline for Currently untested/Known issues [\#13](https://github.com/chef/chef-provisioning-azure/issues/13)
- Adding a VM to an empty Cloud Service fails with 'Deployment doesn't exists' [\#8](https://github.com/chef/chef-provisioning-azure/issues/8)
- Endpoints as parameters [\#1](https://github.com/chef/chef-provisioning-azure/issues/1)

**Merged pull requests:**

- Adding a CONTRIBUTING document [\#38](https://github.com/chef/chef-provisioning-azure/pull/38) ([tyler-ball](https://github.com/tyler-ball))
- Update README.md [\#37](https://github.com/chef/chef-provisioning-azure/pull/37) ([stuartpreston](https://github.com/stuartpreston))
- Closing down ASM issues in preparation for ARM mode driver [\#35](https://github.com/chef/chef-provisioning-azure/pull/35) ([stuartpreston](https://github.com/stuartpreston))
- Setting SSH username to vm\_user other than specific machine/bootstrap\_options property [\#34](https://github.com/chef/chef-provisioning-azure/pull/34) ([plant42](https://github.com/plant42))
- Adding ancillary resources [\#31](https://github.com/chef/chef-provisioning-azure/pull/31) ([stuartpreston](https://github.com/stuartpreston))

## [v0.3.2](https://github.com/chef/chef-provisioning-azure/tree/v0.3.2) (2015-04-03)
[Full Changelog](https://github.com/chef/chef-provisioning-azure/compare/v0.3.1...v0.3.2)

## [v0.3.1](https://github.com/chef/chef-provisioning-azure/tree/v0.3.1) (2015-04-03)
[Full Changelog](https://github.com/chef/chef-provisioning-azure/compare/v0.3...v0.3.1)

## [v0.3](https://github.com/chef/chef-provisioning-azure/tree/v0.3) (2015-04-02)
[Full Changelog](https://github.com/chef/chef-provisioning-azure/compare/v0.2.1...v0.3)

**Closed issues:**

- A10 and A11 VM role sizes not supported [\#14](https://github.com/chef/chef-provisioning-azure/issues/14)
- Newer sizes of Azure VM such as 'Standard\_D1' are not available [\#9](https://github.com/chef/chef-provisioning-azure/issues/9)
- ability to use custom images in provisioning azure nodes [\#5](https://github.com/chef/chef-provisioning-azure/issues/5)
- Net::SSH::AuthenticationFailed [\#2](https://github.com/chef/chef-provisioning-azure/issues/2)

**Merged pull requests:**

- Add .azure/azureProfile.json and Azure environment variable support [\#25](https://github.com/chef/chef-provisioning-azure/pull/25) ([stuartpreston](https://github.com/stuartpreston))
- Support for Windows VM roles with WinRM bootstrap support for Azure driver [\#15](https://github.com/chef/chef-provisioning-azure/pull/15) ([stuartpreston](https://github.com/stuartpreston))
- Fixing readme example to include required options [\#12](https://github.com/chef/chef-provisioning-azure/pull/12) ([stuartpreston](https://github.com/stuartpreston))

## [v0.2.1](https://github.com/chef/chef-provisioning-azure/tree/v0.2.1) (2015-02-26)
[Full Changelog](https://github.com/chef/chef-provisioning-azure/compare/v0.2...v0.2.1)

**Closed issues:**

- Can only provision and bootstrap the first VM in any given cloud service [\#6](https://github.com/chef/chef-provisioning-azure/issues/6)

**Merged pull requests:**

- Allow multiple VMs to be created per cloud service and bootstrapped using their public SSH ports [\#7](https://github.com/chef/chef-provisioning-azure/pull/7) ([stuartpreston](https://github.com/stuartpreston))

## [v0.2](https://github.com/chef/chef-provisioning-azure/tree/v0.2) (2015-02-11)
[Full Changelog](https://github.com/chef/chef-provisioning-azure/compare/v0.1...v0.2)

**Merged pull requests:**

- Changes to paths and filenames to match chef-provisioning expectations [\#4](https://github.com/chef/chef-provisioning-azure/pull/4) ([stuartpreston](https://github.com/stuartpreston))

## [v0.1](https://github.com/chef/chef-provisioning-azure/tree/v0.1) (2014-11-05)
**Merged pull requests:**

- Rename to chef-provisioning-azure [\#3](https://github.com/chef/chef-provisioning-azure/pull/3) ([jkeiser](https://github.com/jkeiser))



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*