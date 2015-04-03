# Changelog

## 0.3.2 (2015-04-03)

- Updated dependencies on Azure SDK, compatibility with chef-client 12.2.1

## 0.3.1 (2015-04-02)

- Fix second converge issues, support chef-provisioning 1.0

## 0.3 (2015-04-01)

- (BREAKING) No longer use .azure/config for configuration [(docs/configuration.md)](docs/configuration.md) (@jkeiser)
- Use available credentials and subscription if user has used azure-cli previously (@jkeiser)
- Support for Windows VM images, including WinRM bootstrap (@stuartpreston)
- Supoprt for custom TCP/UDP endpoint mapping per machine (@stuartpreston)
- Support for creating a VM role from a user-captured image (@stuartpreston)
- Support for D, DS and G machine sizes (@stuartpreston)

## 0.2.1 (2015-15-02)

- Fix issue preventing multiple machines from being created (@stuartpreston)

## 0.2 (2015-11-02)

- Get working with latest chef-provisioning

## 0.1 (2014-16-10)

- Initial revision.  Use at own risk :)
