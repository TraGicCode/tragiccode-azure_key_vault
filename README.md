# azure_key_vault

[![Puppet Forge Version](https://img.shields.io/puppetforge/v/tragiccode/azure_key_vault.svg)](https://forge.puppetlabs.com/tragiccode/azure_key_vault)
[![Puppet Forge Pdk Version](http://img.shields.io/puppetforge/pdk-version/tragiccode/azure_key_vault.svg)](https://forge.puppetlabs.com/tragiccode/azure_key_vault)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/tragiccode/azure_key_vault.svg)](https://forge.puppetlabs.com/tragiccode/azure_key_vault)
[![Puppet Forge Endorsement](https://img.shields.io/puppetforge/e/tragiccode/azure_key_vault.svg)](https://forge.puppetlabs.com/tragiccode/azure_key_vault)



#### Table of Contents

1. [Description](#description)
1. [Setup](#setup)
1. [How it works](#how-it-works)
    * [Puppet Function](#puppet-function)
    * [Hiera Backend](#hiera-backend)
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

* Puppet Agent 6.0.0 or later.
* Azure Subscription with one or more vaults already created and loaded with secrets.
* Puppet Server running on a machine with Managed Service Identity ( MSI ) and assigned the appropriate permissions
  to pull secrets from the vault. To learn more or get help with this please visit https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/tutorial-windows-vm-access-nonaad

## How it works

### Puppet Function

This module contains a Puppet 4 function that allows you to securely retrieve secrets from Azure Key Vault.  In order to get started simply call the function in your manifests passing in the required parameters:

```puppet
$important_secret = azure_key_vault::secret('production-vault', 'important-secret', {
  metadata_api_version => '2018-04-02',
  vault_api_version    => '2016-10-01',
})
```

This example fetches the latest secret with the name "important-secret" from the vault named "production-vault".  Under the covers it calls the Azure instance metadata service api to get an access token in order to make authenticated requests to the vault api on-behalf-of the MSI.  Once the secret is returned you can begin to use it throughout your puppet code.

> NOTE: In order to improve performance and avoid the request limit for the metadata service api the api token retrieved once then stored in a cache that exists for the duration of the puppet run.

In the above example the api_versions hash is important.  It is pinning both of the Azure specific api's ( instance metadata api & vault api ) used under the hood to specific versions so that you have full control as to when your puppet code starts calling newer/older versions of the apis.  In order to understand what versions are available to your regions please visit the azure documentation

* Instance Metadata Service Versions ( https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service )
* Vault Versions ( TBD )

### Hiera Backend

This module contains a Hiera 5 backend that allows you to securely retrieve secrets from Azure key vault and use them in hiera.

Add a new entry to the `hierarchy` hash in `hiera.yaml` providing the following required lookup options:

```yaml
- name: 'Azure Key Vault Secrets'
    lookup_key: azure_key_vault::lookup
    options:
      vault_name: production-vault
      vault_api_version: '2016-10-01'
      metadata_api_version: '2018-04-02'
      key_replacement_token: '-'
      confine_to_keys:
        - '^azure_.*'
        - '^.*_password$'
        - '^password.*'
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

You can use a fact to specify different vaults for different groups of nodes. It is
recommended to use a trusted fact such as trusted.extensions.pp_environment as these facts
cannot be altered.
Alternatively a custom trusted fact can be included [in the certificate request](https://puppet.com/docs/puppet/latest/ssl_attributes_extensions.html)

```yaml
- name: 'Azure Key Vault Secrets from trusted fact'
    lookup_key: azure_key_vault::lookup
    options:
      vault_name: "%{trusted.extensions.pp_environment}"
      vault_api_version: '2016-10-01'
      metadata_api_version: '2018-04-02'
      key_replacement_token: '-'
      confine_to_keys:
        - '^azure_.*'
        - '^.*_password$'
        - '^password.*'
```

### What is confine_to_keys?

By design, hiera will traverse the configured heiarchy for a given key until one is found.  This means that there can be a potentially large number of web requests against azure key vault. In order to improve performance and prevent hitting the Azure KeyVault rate limits ( ex: currently there is a maximum of 2,000 lookups every 10 seconds allowed against a key vault), the confine_to_keys allows you to provide an array of regexs that help avoid making a remote call.

As an example, if you defined your confine_to_keys as shown below, hiera will only make a web request to get the secret in azure key vault when the key being lookedup matches atleast one of the provided regular expressions in the confine_to_keys array.

```yaml
- name: 'Azure Key Vault Secrets from trusted fact'
    lookup_key: azure_key_vault::lookup
    options:
      vault_name: "%{trusted.extensions.pp_environment}"
      vault_api_version: '2016-10-01'
      metadata_api_version: '2018-04-02'
      key_replacement_token: '-'
      confine_to_keys:
        - '^azure_.*'
        - '^.*_password$'
        - '^password.*'
```

**NOTE: The confine_to_keys is very important to make you sure get right.  As a best practice, come up with some conventions to avoid having a large number of regexs you have to add/update/remove and also test.  The above example provides a great starting point.**

### What is key_replacement_token?

KeyVault secret names can only contain the characters `0-9`, `a-z`, `A-Z`, and `-`.

When relying on automatic parameter lookup, this is almost always going to contain the module delimiter (`::`) or underscores.

This module will automatically convert the variable name to a valid value by replacing every invalid character with the `key_replacement_token` value, which defaults to `-`.

For example, the hiera variable `puppetdb::master::config::puppetdb_server` will automatically be converted to `puppetdb--master--config--puppetdb-server` before being queried up in KeyVault.

When troubleshooting, you can run hiera from the commandline with the `--explain` option to see the key name being used :

      Using normalized KeyVault secret key for lookup: puppetdb--master--config--puppetdb-server

## How it's secure by default

In order to prevent accidental leakage of your secrets throughout all of the locations puppet stores information the returned value of the `azure_key_vault::secret` function returns a string wrapped in a Sensitive data type.  Lets look at an example of what this means and why it's important.  Below is an example of pulling a secret and trying to output the value in a notice function.

```puppet
$secret = azure_key_vault::secret('production-vault', 'important-secret', {
  metadata_api_version => '2018-04-02',
  vault_api_version    => '2016-10-01',
})
notice($secret)
```

This outputs `Notice: Scope(Class[main]): Sensitive [value redacted]`

Note that the Hiera backend can also return a string wrapped with the Sensitive type, but you need to explicitly add a `lookup_options` configuration.

```yaml
# Put in your common.yaml file
lookup_options:
  '^.*_password$*': # have this regex match the ones from confine_to_keys
    convert_to: 'Sensitive'
```

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
  metadata_api_version => '2018-04-02',
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
  metadata_api_version => '2018-04-02',
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
    metadata_api_version => '2018-04-02',
    vault_api_version    => '2016-10-01',
  }),
  ensure    => file,
}
```

### Retrieving a specific version of a secret

By Default, the latest secret is always retrieved from the vault.  If you want to ensure only a specific version of a secret is retrieved simply pass a parameter to specify the exact version you want.

```puppet
$admin_password_secret = azure_key_vault::secret('production-vault', 'admin-password', {
  metadata_api_version => '2018-04-02',
  vault_api_version    => '2016-10-01',
},
'067e89990f0a4a50a7bd854b40a56089')
```

**NOTE: Retrieving a specific version of a secret is currently not available via the hiera backend**

### Retrieving a certificate

Azure Key Vault stores certificates "under-the-covers" as secrets.  This means you retrieving certificates can be done using the same `azure_key_vault::secret`
function. One thing to keep in mind is that the certificate will be based64 encoded and will need to be decoded before usage to have a valid certificate file.

```puppet
$certificate_secret = azure_key_vault::secret('production-vault', "webapp-certificate", {
  metadata_api_version => '2018-04-02',
  vault_api_version    => '2016-10-01',
})

file { "C:/tmp/webapp-certificate.pfx" :
  content   => base64('decode', "${certificate_secret.unwrap}"),
  ensure    => file,
}

sslcertificate { "Install-WebApp-Certificate" :
  name       => "${filename}",
  location   => 'C:\tmp',
  root_store => 'LocalMachine',
  thumbprint => "${certificate_thumbprint}"
}
```

**NOTE: Retrieving a specific version of a secret is currently not available via the hiera backend**

## Reference

See [REFERENCE.md](https://github.com/tragiccode/tragiccode-azure_key_vault/blob/master/REFERENCE.md)

## Development

## Contributing

1. Fork it ( <https://github.com/tragiccode/tragiccode-azure_key_vault/fork> )
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create a new Pull Request
