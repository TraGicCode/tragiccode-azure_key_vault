# azure_key_vault

[![Puppet Forge Version](https://img.shields.io/puppetforge/v/tragiccode/azure_key_vault.svg)](https://forge.puppetlabs.com/tragiccode/azure_key_vault)
[![Puppet Forge Pdk Version](http://img.shields.io/puppetforge/pdk-version/tragiccode/azure_key_vault.svg)](https://forge.puppetlabs.com/tragiccode/azure_key_vault)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/tragiccode/azure_key_vault.svg)](https://forge.puppetlabs.com/tragiccode/azure_key_vault)
[![Puppet Forge Endorsement](https://img.shields.io/puppetforge/e/tragiccode/azure_key_vault.svg)](https://forge.puppetlabs.com/tragiccode/azure_key_vault)

## Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Authentication Methods](#authentication-methods)
    * [Managed Service Identity (MSI)](#managed-service-identity-msi)
    * [Managed Identity for Azure Arc-enabled servers](#managed-identity-for-azure-arc-enabled-servers)
    * [Service Principal Credentials](#service-principal-credentials)
    * [Which Authentication Method Should I Use?](#which-authentication-method-should-i-use)
1. [Usage](#usage)
    * [Puppet Function](#puppet-function)
    * [Hiera Backend](#hiera-backend)
    * [Manual Lookups](#manual-lookups)
1. [Configuration Options](#configuration-options)
    * [API Versions](#api-versions)
    * [confine_to_keys](#confine_to_keys)
    * [key_replacement_token](#key_replacement_token)
    * [strip_from_keys](#strip_from_keys)
    * [prefixes](#prefixes)
    * [Using Facts](#using-facts)
1. [Security](#security)
    * [How It's Secure by Default](#how-its-secure-by-default)
    * [Working with Sensitive Data](#working-with-sensitive-data)
1. [Examples](#examples)
    * [Embedding a Secret in a File](#embedding-a-secret-in-a-file)
    * [Retrieving a Specific Version](#retrieving-a-specific-version)
    * [Retrieving a Certificate](#retrieving-a-certificate)
1. [Reference](#reference)
1. [Development and Contributing](#development-and-contributing)

## Description

Secure secrets management is essential for protecting data in the cloud. Azure Key Vault is Microsoft's solution for this purpose. This module provides a Puppet function and a Hiera backend that allow you to securely fetch secrets from Azure Key Vault on the Puppet server and embed them into catalogs during compilation time.

## Requirements

* **Puppet Agent**: Version 6.0.0 or later
* **Azure Subscription**: One or more Key Vaults created and populated with secrets
* **Authentication**: One of the authentication methods described below

## Authentication Methods

This module supports three authentication methods for accessing Azure Key Vault. Each method has different use cases and security implications.

### Managed Service Identity (MSI)

Managed Service Identity allows your Puppet Server to authenticate to Azure Key Vault without storing credentials. This requires your Puppet Server to run on an Azure VM with MSI enabled and granted appropriate permissions to access the Key Vault.

**Setup**: Configure MSI on your Azure VM and grant it appropriate Key Vault permissions. [Learn more](https://docs.microsoft.com/en-us/azure/active-directory/managed-service-identity/tutorial-windows-vm-access-nonaad)

### Managed Identity for Azure Arc-enabled servers

For servers running outside of Azure (on-premises or other clouds), Azure Arc-enabled servers provide managed identity capabilities similar to MSI.

**Setup**: Follow Microsoft's documentation to set up an Azure Arc-enabled server. [Learn more](https://learn.microsoft.com/en-us/azure/azure-arc/servers/learn/quick-enable-hybrid-vm)

### Service Principal Credentials

Service Principal authentication uses a client ID and secret to authenticate to Azure Key Vault. This requires creating a Service Principal in Azure Active Directory and securely storing its credentials.

**Setup**: Create a Service Principal and grant it appropriate Key Vault permissions. [Learn more](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)

### Which Authentication Method Should I Use?

**Recommended Priority:**

1. **Managed Service Identity (MSI)** - Use this when your Puppet Server runs in Azure. No credential management required!
2. **Managed Identity for Azure Arc-enabled servers** - Use this when your Puppet Server runs outside Azure but can be Arc-enabled.
3. **Service Principal Credentials** - Use this only when the above options are not available. Requires secure credential storage and management.

## Usage

This module can be used in two ways: as a Puppet function in your manifests, or as a Hiera backend for automatic parameter lookup.

### Puppet Function

The module provides the `azure_key_vault::secret` function to retrieve secrets directly in your Puppet manifests.

#### Function Example: Using MSI

```puppet
$important_secret = azure_key_vault::secret('production-vault', 'important-secret', {
  vault_api_version    => '2016-10-01',
  metadata_api_version => '2018-04-02',
})
```

This fetches the latest version of "important-secret" from "production-vault" using MSI for authentication.

> **Performance Note:** To improve performance and avoid request limits, the API token is cached for the duration of the Puppet run.

#### Function Example: Using Azure Arc

```puppet
$important_secret = azure_key_vault::secret('production-vault', 'important-secret', {
  vault_api_version            => '2016-10-01',
  metadata_api_version         => '2018-04-02',
  use_azure_arc_authentication => true,
})
```

Set `use_azure_arc_authentication => true` to use Azure Arc managed identity for authentication.

#### Function Example: Using Service Principal

```puppet
$important_secret = azure_key_vault::secret('production-vault', 'important-secret', {
  vault_api_version    => '2016-10-01',
  service_principal_credentials => {
    tenant_id     => '00000000-0000-1234-1234-000000000000',
    client_id     => '00000000-0000-1234-1234-000000000000',
    client_secret => lookup('azure_client_secret'),
  }
})
```

The `client_secret` must be of type `Sensitive` to prevent accidental leakage in logs and reports.

### Hiera Backend

The module provides a Hiera 5 backend that integrates with Puppet's automatic parameter lookup (APL).

#### Hiera Example: Using MSI

Add this to your `hiera.yaml`:

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

#### Hiera Example: Using Azure Arc

```yaml
- name: 'Azure Key Vault Secrets'
  lookup_key: azure_key_vault::lookup
  options:
    vault_name: production-vault
    vault_api_version: '2016-10-01'
    metadata_api_version: '2018-04-02'
    use_azure_arc_authentication: true
    key_replacement_token: '-'
    confine_to_keys:
      - '^azure_.*'
      - '^.*_password$'
      - '^password.*'
```

#### Hiera Example: Using Service Principal

```yaml
- name: 'Azure Key Vault Secrets'
  lookup_key: azure_key_vault::lookup
  options:
    vault_name: production-vault
    vault_api_version: '2016-10-01'
    service_principal_credentials: '/etc/puppetlabs/puppet/azure_key_vault_credentials.yaml'
    key_replacement_token: '-'
    confine_to_keys:
      - '^azure_.*'
      - '^.*_password$'
      - '^password.*'
```

The credentials file should be in YAML format:

```yaml
tenant_id: '00000000-0000-1234-1234-000000000000'
client_id: '00000000-0000-1234-1234-000000000000'
client_secret: some-secret
```

### Manual Lookups

You can retrieve secrets in Puppet code using the `lookup` function:

```puppet
notify { 'lookup':
  message => lookup('important-secret'),
}
```

In Hiera files, use the `alias` function to preserve the `Sensitive` data type:

```yaml
some_class::password: "%{alias('important-secret')}"
```

**Important:** Use `alias`, not `lookup`, in Hiera files. The `lookup` function interpolates as a string, which breaks the `Sensitive` type. [More information](https://www.puppet.com/docs/puppet/7/hiera_merging.html#interpolation_functions)

**Best Practice:** Use Hiera's automatic parameter lookup (APL) instead of manual lookups when possible.

## Configuration Options

### API Versions

The `vault_api_version` and `metadata_api_version` parameters pin the Azure APIs to specific versions, giving you control over when your Puppet code uses different API versions.

* **Instance Metadata Service Versions**: [Azure documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service)
* **Vault API Versions**: Check the Azure Key Vault documentation for available versions

### confine_to_keys

By design, Hiera traverses the configured hierarchy for each key until one is found. This can result in many web requests to Azure Key Vault. The `confine_to_keys` option improves performance and prevents rate limiting (Azure Key Vault allows 2,000 lookups every 10 seconds per vault) by specifying regular expressions that determine when to query Key Vault.

Hiera will only query Key Vault when the lookup key matches at least one of the provided regular expressions.

**Example:**

```yaml
confine_to_keys:
  - '^azure_.*'
  - '^.*_password$'
  - '^password.*'
```

**Best Practice:** Establish naming conventions for your secrets to minimize the number of regular expressions needed.

### key_replacement_token

Key Vault secret names can only contain characters `0-9`, `a-z`, `A-Z`, and `-`. Puppet variable names often contain `::` (module delimiter) or underscores, which are invalid in Key Vault.

This module automatically converts variable names to valid Key Vault secret names by replacing each invalid character with the `key_replacement_token` (default: `-`).

**Example:** `puppetdb::master::config::puppetdb_server` becomes `puppetdb--master--config--puppetdb-server`

**Troubleshooting:** Use `hiera --explain` to see the normalized key name:

```text
Using normalized KeyVault secret key for lookup: puppetdb--master--config--puppetdb-server
```

### strip_from_keys

The `strip_from_keys` option removes specified patterns from secret names before lookup. This is useful when `confine_to_keys` adds prefixes that you don't want in your Key Vault secret names.

**Example:**

```yaml
- name: 'Azure Key Vault Secrets'
  lookup_key: azure_key_vault::lookup
  options:
    vault_name: "prod-key-vault"
    vault_api_version: '2016-10-01'
    metadata_api_version: '2018-04-02'
    key_replacement_token: '-'
    strip_from_keys:
      - 'azure_'
    confine_to_keys:
      - '^azure_.*'
```

With this configuration, a lookup for `azure_sql_user_password` searches for `sql-user-password` in Key Vault.

**Advanced Example - Stripping Module Paths:**

```yaml
strip_from_keys:
  - '^profile::.*::'
```

A lookup for `profile::windows::sqlserver::azure_sql_user_password` searches for `azure_sql_user_password`.

### prefixes

The `prefixes` option creates a hierarchy within Key Vault, similar to the YAML backend. This enables node-specific secrets and custom lookup hierarchies. It's also useful for migrating from HashiCorp Hiera Vault, which has similar behavior.

**Example:**

```yaml
- name: 'Azure Key Vault Secrets'
  lookup_key: azure_key_vault::lookup
  options:
    vault_name: secrets-vault
    vault_api_version: '2016-10-01'
    metadata_api_version: '2018-04-02'
    key_replacement_token: '-'
    prefixes:
      - nodes--%{trusted.hostname}--
      - common--
    confine_to_keys:
      - '^azure_.*'
```

For a node with `trusted.hostname` of `WIN-SQL01.domain.com`, a lookup for `azure_sql_user_password` checks:

1. `nodes--WIN-SQL-domain-com--azure-sql-user-password` (node-specific)
2. `common--azure-sql-user-password` (shared, if node-specific not found)

**Note:** Prefixes are normalized using the `key_replacement_token` to ensure compatibility with Key Vault naming requirements.

### Using Facts

You can use facts to specify different vaults for different node groups. Use trusted facts when possible, as they cannot be altered.

**Example:**

```yaml
- name: 'Azure Key Vault Secrets'
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

You can also use [custom trusted facts in certificate requests](https://puppet.com/docs/puppet/latest/ssl_attributes_extensions.html).

## Security

### How It's Secure by Default

To prevent accidental leakage of secrets in logs, reports, and other Puppet-generated data, the `azure_key_vault::secret` function and Hiera backend return secrets wrapped in Puppet's `Sensitive` data type.

**Example:**

```puppet
$secret = azure_key_vault::secret('production-vault', 'important-secret', {
  metadata_api_version => '2018-04-02',
  vault_api_version    => '2016-10-01',
})
notice($secret)
```

**Output:** `Notice: Scope(Class[main]): Sensitive [value redacted]`

### Working with Sensitive Data

Sometimes you need to unwrap secrets to manipulate them or use them with resources that don't support the `Sensitive` type.

#### Special Case 1: Modifying a Secret

To modify a secret, follow this 3-step process: unwrap, modify, rewrap.

```puppet
$secret = azure_key_vault::secret('production-vault', 'important-secret', {
  metadata_api_version => '2018-04-02',
  vault_api_version    => '2016-10-01',
})

$rewrapped_secret = Sensitive("password: ${secret.unwrap}")

file { 'C:\\DataForApplication.secret':
  content   => $rewrapped_secret,
  ensure    => file,
}
```

#### Special Case 2: Resources Without Sensitive Support

Not all resources support the `Sensitive` type. Check the documentation or code to determine support. If a resource doesn't support `Sensitive`, you can unwrap the secret, but you're no longer guaranteed it won't leak in logs or reports.

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

**Note:** If you encounter a resource that doesn't support `Sensitive`, please open an issue with the maintainer.

## Examples

### Embedding a Secret in a File

Retrieve a secret and write it to a file on a node:

```puppet
file { 'C:\\DataForApplication.secret':
  content   => azure_key_vault::secret('production-vault', 'important-secret', {
    metadata_api_version => '2018-04-02',
    vault_api_version    => '2016-10-01',
  }),
  ensure    => file,
}
```

### Retrieving a Specific Version

By default, the latest version of a secret is retrieved. To retrieve a specific version, pass the version ID as the fourth parameter:

```puppet
$admin_password_secret = azure_key_vault::secret('production-vault', 'admin-password', {
  metadata_api_version => '2018-04-02',
  vault_api_version    => '2016-10-01',
},
'067e89990f0a4a50a7bd854b40a56089')
```

**Note:** Retrieving specific versions is not available via the Hiera backend.

### Retrieving a Certificate

Azure Key Vault stores certificates as secrets. Retrieve them using `azure_key_vault::secret`. The certificate will be base64 encoded and must be decoded before use.

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

**Note:** Retrieving specific certificate versions is not available via the Hiera backend.

## Reference

See [REFERENCE.md](https://github.com/tragiccode/tragiccode-azure_key_vault/blob/master/REFERENCE.md)

## Development and Contributing

We welcome contributions! To contribute:

1. Fork the repository (<https://github.com/tragiccode/tragiccode-azure_key_vault/fork>)
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create a new Pull Request
