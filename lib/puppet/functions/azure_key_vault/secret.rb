require_relative '../../../puppet_x/tragiccode/azure'

# Retrieves secrets from Azure's Key Vault.
Puppet::Functions.create_function(:'azure_key_vault::secret', Puppet::Functions::InternalFunction) do
  # @param vault_name Name of the vault in your Azure subcription.
  # @param secret_name Name of the secret to be retrieved.
  # @param api_endpoint_hash TODO(description mismatch) A Hash of the exact versions of the metadata_api_version and vault_api_version to use.
  # @param secret_version The version of the secret you want to retrieve.  This parameter is optional and if not passed the default behavior is to retrieve the latest version.
  # @return [Sensitive[String]] Returns the secret as a String wrapped with the Sensitive data type.
  dispatch :secret do
    cache_param
    required_param 'String', :vault_name
    required_param 'String', :secret_name
    # TODO: Enforcing the type clarifies what is expected from this function, but it has the potential to break callers
    param 'Struct[{
      vault_api_version => String,
      Optional[metadata_api_version] => String,
      Optional[azure_tenant_id] => String,
      Optional[azure_client_id] => String,
      Optional[azure_client_secret] => String
    }]', :api_endpoint_hash
    optional_param 'String', :secret_version
  end

  def secret(cache, vault_name, secret_name, api_endpoint_hash, secret_version = '')
    Puppet.debug("vault_name: #{vault_name}")
    Puppet.debug("secret_name: #{secret_name}")
    Puppet.debug("secret_version: #{secret_version}")
    Puppet.debug("metadata_api_version: #{api_endpoint_hash['metadata_api_version']}")
    Puppet.debug("vault_api_version: #{api_endpoint_hash['vault_api_version']}")
    Puppet.debug("azure_tenant_id: #{api_endpoint_hash['azure_tenant_id']}")
    Puppet.debug("azure_client_id: #{api_endpoint_hash['azure_client_id']}")
    cache_hash = cache.retrieve(self)
    access_token_id = :"access_token_#{vault_name}"
    unless cache_hash.key?(access_token_id)
      Puppet.debug("retrieving access token since it's not in the cache")
      metadata_api_version = api_endpoint_hash['metadata_api_version']
      azure_client_id = api_endpoint_hash['azure_client_id']
      if metadata_api_version && azure_client_id
        raise ArgumentError, 'metadata_api_version and azure_client_id cannot be used together'
      end
      if !metadata_api_version && !azure_client_id
        raise ArgumentError, 'hash must contain at least one of metadata_api_version or azure_client_id'
      end

      if azure_client_id
        credentials = api_endpoint_hash.slice('azure_tenant_id', 'azure_client_id', 'azure_client_secret')
        access_token = TragicCode::Azure.get_access_token_service_principal(credentials)
      else
        access_token = TragicCode::Azure.get_access_token(metadata_api_version)
      end
      cache_hash[access_token_id] = access_token
    end

    secret_value = TragicCode::Azure.get_secret(
      vault_name,
      secret_name,
      api_endpoint_hash['vault_api_version'],
      cache_hash[access_token_id],
      secret_version,
    )

    raise Puppet::Error, "The secret named #{secret_name} could not be found in a vault named #{vault_name}" if secret_value.nil?

    Puppet::Pops::Types::PSensitiveType::Sensitive.new(secret_value)
  end
end
