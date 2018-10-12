# azure_key_vault

[![Puppet Forge](http://img.shields.io/puppetforge/v/tragiccode/azure_key_vault.svg)](https://forge.puppetlabs.com/tragiccode/azure_key_vault)

#### Table of Contents

1. [Description](#description)
1. [Setup](#setup)
1. [How it works](#how-it-works)
1. [How it's secure by default](#how-its-secure-by-default)
1. [Usage](#usage)
    * [Embedding a secret in a file](#embedding-a-secret-in-a-file)
    * [Retrieving a specific version of a secret](#retrieving-a-specific-version-of-a-secret)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Development - Guide for contributing to the module](#development)

## Description

Secure secrets management is essential and critical in order to protect data in the cloud.  Key Vault is Microsoft Azure's solution to make this happen.
This module provides a Puppet function and a Hiera backend that allows you to easily fetch secrets securely on the puppet server and embed them into catalogs during compilation time.

## Setup

The module requires the following:

* Puppet Agent 4.7.1 or later.
* Azure Subscription with one or more vaults already created and loaded with secrets.
* Puppet Server running on a machine with Managed Service Identity ( MSI ) and assigned the appropriate permissions 
  to pull secrets from the vault. To learn more or get help with this please visit https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/tutorial-windows-vm-access-nonaad

## How the function works

This module contains a Puppet 4 function that allows you to securely retrieve secrets from Azure Key Vault.  In order to get started simply call the function in your manifests passing in the required parameters:

```puppet
$important_secret = azure_key_vault::secret('production-vault', 'important-secret', {
  metadata_api_version => '2018-02-01',
  vault_api_version    => '2016-10-01',
})
```

This example fetches the latest secret with the name "important-secret" from the vault named "production-vault".  Under the covers it calls the Azure instance metadata service api to get an access token in order to make authenticated requests to the vault api on-behalf-of the MSI.  Once the secret is returned you can begin to use it throughout your puppet code.

In the above example the api_versions hash is important.  It is pinning both of the Azure specific api's ( instance metadata api & vault api ) used under the hood to specific versions so that you have full control as to when your puppet code starts calling newer/older versions of the apis.  In order to understand what versions are available to your regions please visit the azure documentation

* Instance Metadata Service Versions ( https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service )
* Vault Versions ( TBD )

## How the hiera backend works

This module contains a Hiera 5 backend that allows you to securely retrieve secrets from Azure key vault and use them in hiera.

Add a new entry to the `hierarchy` hash in `hiera.yaml` referencing the vault name and API versions:

```yaml
- name: 'Azure Key Vault Secrets'
    lookup_key: azure_key_vault::lookup
    options:
      vault_name: production-vault
      vault_api_version: '2016-10-01'
      metadata_api_version: '2018-02-01'
```

To retrieve a secret in puppet code you can use the `lookup` function:

```puppet
notify { 'lookup':
  message => lookup('important-secret'),
}
```

This function can also be used in hiera files, for example to set class parameters:

```yaml
some_class::password: "%{lookup('important-secret')}"
```

## How it's secure by default

In order to prevent accidental leakage of your secrets throughout all of the locations puppet stores information the returned value of the `azure_key_vault::secret` function is a string wrapped in a Sensitive data type.  Lets look at an example of what this means and why it's important.  Below is an example of pulling a secret and trying to output the value in a notice function.

```puppet
$secret = azure_key_vault::secret('production-vault', 'important-secret', {
  metadata_api_version => '2018-02-01',
  vault_api_version    => '2016-10-01',
})
notice($secret)
```

This outputs `Notice: Scope(Class[main]): Sensitive [value redacted]`

Note that the Hiera backend returns the secrets as strings rather than wrapped with the Sensitive type.

However, Sometimes you need to unwrap the secret to get to the original data.  This is typically needed under the following but not limited to circumstances.

1. You need to programatically change/alter/append to the secret that was retrieved.
1. The resource you are passing the secret to does not natively handle the Sensitive data type.

These 2 special cases are discussed in detail next.

#### Special Case 1 - Programatically Changing/Altering/Appending to a secret

In order to change the original secret you always follow the same 3 step process.

1. unwrap
1. alter/change
1. rewrap

```puppet
$secret = azure_key_vault::secret('production-vault', 'important-secret', {
  metadata_api_version => '2018-02-01',
  vault_api_version    => '2016-10-01',
})

$rewraped_secret = Sensitive("password: ${secret.unwrap}")

file { 'C:\\DataForApplication.secret':
  content   => $rewraped_secret,
  ensure    => file,
}
```

#### Special Case 2 - A Resource doesn't natively support Puppet's Sensitive Data type

Unfortunately, All resource's don't magically handle the sensitive data type.  In order to know if a resource supports it or not simply read the documentation or browse through the code if it's available.  If you are using a resource that doesn't support the sensitive data type you can unwrap the secret but but you are no longer guaranteed the secret will not get leaked in logs/reports depending on what the resource does with the secret you passed to it.  Below is an example of an imaginary resource that doesn't support the sensitive data type and how you can unwrap to handle this situation.

```puppet
$admin_password_secret = azure_key_vault::secret('production-vault', 'important-secret', {
  metadata_api_version => '2018-02-01',
  vault_api_version    => '2016-10-01',
})

resource_not_supporting_sensitive { 'my_resource':
    username => 'admin',
    password => $admin_password_secret.unwrap,
}
```

**NOTE: Whatever resource you run into that doesn't support the sensitive data type you should open a issue/ticket with the person/organization maintaining the resource.**

## Usage

### Embedding a secret in a file

Below shows an example of how to retrieve a secret and place it in a file on a node.  This is typically done because some application/process is expecting the file to exist with the secret in order to get some work done ( such as connecting to a database ).

```puppet
file { 'C:\\DataForApplication.secret':
  content   => azure_key_vault::secret('production-vault', 'important-secret', {
    metadata_api_version => '2018-02-01',
    vault_api_version    => '2016-10-01',
  }),
  ensure    => file,
}
```

### Retrieving a specific version of a secret

By Default, the latest secret is always retrieved from the vault.  If you want to ensure only a specific version of a secret is retrieved simply pass a parameter to specify the exact version you want.

This parameter is not available for the Hiera backend.

```puppet
$admin_password_secret = azure_key_vault::secret('production-vault', 'admin-password', {
  metadata_api_version => '2018-02-01',
  vault_api_version    => '2016-10-01',
},
'067e89990f0a4a50a7bd854b40a56089')
```

## Reference

See [REFERENCE.md](REFERENCE.md)

## Development

## Contributing

1. Fork it ( <https://github.com/tragiccode/tragiccode-azure_key_vault/fork> )
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create a new Pull Request