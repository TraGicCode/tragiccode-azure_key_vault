require_relative '../../../puppet_x/tragiccode/azure'

# Retrieves secrets from Azure's Key Vault.
Puppet::Functions.create_function(:'azure_key_vault::secret') do
  # @param vault_name Name of the vault in your Azure subcription.
  # @param secret_name Name of the secret to be retrieved.
  # @param api_versions_hash A Hash of the exact versions of the metadata_api_version and vault_api_version to use.
  # @param secret_version The version of the secret you want to retrieve.  This parameter is optional and if not passed the default behavior is to retrieve the latest version.
  # @return [Sensitive[String]] Returns the secret as a String wrapped with the Sensitive data type.
  dispatch :secret do
    required_param 'String', :vault_name
    required_param 'String', :secret_name
    required_param 'Hash',   :api_versions_hash
    optional_param 'String', :secret_version
  end

  def secret(vault_name, secret_name, api_versions_hash, secret_version = '')
    Puppet.debug("vault_name: #{vault_name}")
    Puppet.debug("secret_name: #{secret_name}")
    Puppet.debug("secret_version: #{secret_version}")
    Puppet.debug("metadata_api_version: #{api_versions_hash['metadata_api_version']}")
    Puppet.debug("vault_api_version: #{api_versions_hash['vault_api_version']}")
    access_token = TragicCode::Azure.get_access_token(api_versions_hash['metadata_api_version'])
    secret_value = TragicCode::Azure.get_secret(
      vault_name,
      secret_name,
      api_versions_hash['vault_api_version'],
      access_token,
      secret_version,
    )

    Puppet::Pops::Types::PSensitiveType::Sensitive.new(secret_value)
  end
end
