# Configuration

chef-provisioning-azure configuration (and chef-provisioning in general) has several principles:

- A driver URL should be enough to pick the correct account, even if you have many configured on your machine
- A driver URL should work regardless of what user (and credentials) will be used to access the account
- If you already have Azure set up for command line use, chef-provisioning-azure will Just Work
- You can provide credentials that never hit the disk (memory only) to limit exposure
- You can provide an entire Azure configuration in `Chef::Config` if you so desire

## Setting the driver

When you work with chef-provisioning, you must always specify what *driver* you are using.  You can do this several ways:

1. `driver` on the machine:
   ```ruby
   machine 'mario' do
     driver 'azure'
   end
   ```
2. `with_driver` in the recipe:
   ```ruby
   with_driver 'azure'

   machine 'mario' do
     recipe 'apache2'
   end
   ```
3. The `CHEF_DRIVER` environment variable:
   ```bash
   export CHEF_DRIVER=azure
   ```
4. `Chef::Config` (in a `knife.rb` or `client.rb` file):
   ```ruby
   # knife.rb or client.rb
   driver 'azure'
   ```

## Picking your subscription

You've seen the simple, default URL, `azure`.  But sometimes you have more than one account, more than one subscription to Azure.  If this is the case for you, you can pick among them by specifying the subscription ID or name in the URL:

- `azure:9141ca47-b2fc-444d-f420-bc858ef32f13` (subscription ID)
- `azure:My Very Bestest MSDN Account` (subscription name)

### Driver URLs in machines

When machines, images, load balancers and other objects are stored in Chef, we store a **canonical driver URL** in Chef so that we can find them again.  Even if you specify the default `azure` URL or `azure:<subscription/profile name>`, `chef-provisioning-azure` will transform it to a canonical form with the subscription ID.

This makes it possible to work with multiple accounts in a single Chef server or recipe, and still know which machines are where.

## Finding Credentials

When you specify the driver URL `azure:<subscription id or name>`, we search through subscriptions for the first matching subscription ID or name:

- `Chef::Config.azure_subscriptions`
- `~/.azure/azureProfile.json` - The AWS CLI default location

### `Chef::Config.azure_subscriptions`

The first place we check for subscription information is in `Chef::Config`, in the `azure_subscriptions` key.  For local installations, you won't need to use this (the Azure command line config is probably more convenient), but this can be a great way to configure credentials in a target installation, particularly because you can write arbitrary code that runs on the client (and potentially prevent your credentials from ever hitting the disk).

This is an array of subscriptions that looks something like this:

```ruby
azure_subscriptions [
  {
    subscription_id: '9141ca47-b2fc-444d-f420-bc858ef32f13',
    subscription_name: 'My Very Bestest MSDN Account',
    management_credentials: '~/.azure/mypem.pem'
  },
  {
    subscription_id: '9141ca47-b2fc-444d-f420-bc858ef32f14',
    subscription_name: 'The MSDN Account I Promise I Love Just As Much As My Very Bestest MSDN Account',
    management_credentials: '~/Downloads/mypdx.pfx'
  },
  { publish_settings: '~/Downloads/MyAccount.publishsettings' },
  { azure_profile: '~/.azure/azureProfile.json' }
]
```

We search for subscriptions in the order specified by Chef::Config.azure_subscriptions,
which includes:

Key                           | Description
------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------
`subscription_id`             | The GUID of the subscription.
`subscription_name`           | The name of the subscription.
`management_certificate`      | The path to the actual credentials, or an IO object (optional; if this is not set, the keychain will be searched).
`management_endpoint`         | The management endpoint URL (optional; if not set, the default Azure endpoint will be used).
`is_default`                  | If `true`, this should be considered the default subscription.
`publishsettings`             | The path/glob to one or more `.publishsettings` formatted files, or an IO ject, or a hash with one or more { type: <path&#124;io> } keys, where type=:pem, :pfx or :cert.
`azure_profile`               | The path/glob to one or more `azureProfile.json` formatted files, or an IO object, or a Hash representing the parsed data.
`allow_missing_file`          | If `true`, provisioning will skip the publishsettings or azure_profile if it does not exist; otherwise it will raise an error on missing file.  Defaults to `false`.

By default, we first pick up the Azure SDK environment variables `AZURE_SUBSCRIPTION_ID`, `AZURE_MANAGEMENT_CERTIFICATE`, and `AZURE_MANAGEMENT_ENDPOINT`; if that profile isn't selected, we then read azureProfile.json (from the Azure Cross-Platform CLI).  The default subscription order is:

```ruby
[
  {
    subscription_id: ENV["AZURE_SUBSCRIPTION_ID"],
    management_certificate: ENV["AZURE_MANAGEMENT_CERTIFICATE"],
    management_endpoint: ENV["AZURE_MANAGEMENT_ENDPOINT"]
  },
  {
    publishsettings:
  }
  {
    azure_profile: '~/.azure/azureProfile.json',
    allow_missing_file: true
  }
]
```

If you override `subscriptions` yourself, chef-provisioning-azure not automatically read them in.

### Azure Profiles

An Azure profile is a JSON file with subscription and environment information in it.  Its default location is `~/.azure/azureProfile.json`, and we will load that location after checking `Chef::Config`.

This file is created and manipulated using the [Azure CLI](http://azure.microsoft.com/en-us/documentation/articles/virtual-machines-command-line-tools/).  You can get your certificate into it by running:

```bash
azure account download
azure account import <downloaded filename>
```

If you have multiple accounts (subscriptions), you can choose the default using `azure account set <name>`.  We will pick the same default you have configured in the command line.
