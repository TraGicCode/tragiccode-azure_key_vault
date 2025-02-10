require_relative '../../../puppet_x/tragiccode/azure'

# Retrieves secrets from Azure's Key Vault.
Puppet::Functions.create_function(:'azure_key_vault::secret', Puppet::Functions::InternalFunction) do
  # @param vault_name Name of the vault in your Azure subscription.
  # @param secret_name Name of the secret to be retrieved.
  # @param api_endpoint_hash A Hash with API endpoint and authentication information
  # @param secret_version The version of the secret you want to retrieve.  This parameter is optional and if not passed the default behavior is to retrieve the latest version.
  # @return [Sensitive[String]] Returns the secret as a String wrapped with the Sensitive data type.
  dispatch :secret do
    cache_param
    required_param 'String', :vault_name
    required_param 'String', :secret_name
    param 'Struct[{
      vault_api_version => String,
      Optional[metadata_api_version] => String,
      Optional[service_principal_credentials] => Struct[{
        tenant_id => String,
        client_id => String,
        client_secret => String
      }],
      Optional[use_azure_arc_authentication] => Boolean
    }]', :api_endpoint_hash
    optional_param 'String', :secret_version
    return_type 'Sensitive[String]'
  end

  def secret(cache, vault_name, secret_name, api_endpoint_hash, secret_version = '')
    Puppet.debug("vault_name: #{vault_name}")
    Puppet.debug("secret_name: #{secret_name}")
    Puppet.debug("secret_version: #{secret_version}")
    Puppet.debug("metadata_api_version: #{api_endpoint_hash['metadata_api_version']}")
    Puppet.debug("vault_api_version: #{api_endpoint_hash['vault_api_version']}")
    if api_endpoint_hash['service_principal_credentials']
      partial_credentials = api_endpoint_hash['service_principal_credentials'].slice('tenant_id', 'client_id')
      Puppet.debug("service_principal_credentials: #{partial_credentials}")
    end
    Puppet.debug("use_azure_arc_authentication: #{api_endpoint_hash['use_azure_arc_authentication']}")
    cache_hash = cache.retrieve(self)
    access_token_id = :"access_token_#{vault_name}"
    unless cache_hash.key?(access_token_id)
      Puppet.debug("retrieving access token since it's not in the cache")
      metadata_api_version = api_endpoint_hash['metadata_api_version']
      service_principal_credentials = api_endpoint_hash['service_principal_credentials']
      use_azure_arc_authentication = api_endpoint_hash['use_azure_arc_authentication']

      if !metadata_api_version && !service_principal_credentials
        raise ArgumentError, 'hash must contain at least one of metadata_api_version or service_principal_credentials.'
      end

      # Service principal validation
      if metadata_api_version && service_principal_credentials
        raise ArgumentError, 'metadata_api_version and service_principal_credentials cannot be used together.'
      end

      # Azure arc validation
      if service_principal_credentials && use_azure_arc_authentication
        raise ArgumentError, 'service_principal_credentials and use_azure_arc_authentication cannot be used together.'
      end

      if !metadata_api_version && use_azure_arc_authentication
        raise ArgumentError, 'use_azure_arc_authentication must be used together with metadata_api_version.'
      end

      access_token = if service_principal_credentials
                       TragicCode::Azure.get_access_token_service_principal(service_principal_credentials)
                     elsif use_azure_arc_authentication
                       TragicCode::Azure.get_access_token_azure_arc(metadata_api_version)
                     else
                       TragicCode::Azure.get_access_token(metadata_api_version)
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
