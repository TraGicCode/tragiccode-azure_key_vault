require_relative '../../../puppet_x/tragiccode/azure'

Puppet::Functions.create_function(:'azure_key_vault::lookup') do
  dispatch :lookup_key do
    param 'Variant[String, Numeric]', :secret_name
    param 'Struct[{
      vault_name => String,
      vault_api_version => String,
      Optional[metadata_api_version] => String,
      confine_to_keys => Array[String],
      Optional[key_replacement_token] => String,
      Optional[service_principal_credentials] => String
    }]', :options
    param 'Puppet::LookupContext', :context
    return_type 'Variant[Sensitive, Undef]'
  end

  def lookup_key(secret_name, options, context)
    # This is a reserved key name in hiera
    return context.not_found if secret_name == 'lookup_options'

    confine_keys = options['confine_to_keys']
    if confine_keys
      raise ArgumentError, 'confine_to_keys must be an array' unless confine_keys.is_a?(Array)

      begin
        confine_keys = confine_keys.map { |r| Regexp.new(r) }
      rescue StandardError => e
        raise ArgumentError, "creating regexp failed with: #{e}"
      end

      regex_key_match = Regexp.union(confine_keys)

      unless secret_name[regex_key_match] == secret_name
        context.explain { "Skipping azure_key_vault backend because secret_name '#{secret_name}' does not match confine_to_keys" }
        context.not_found
      end
    end

    normalized_secret_name = TragicCode::Azure.normalize_object_name(secret_name, options['key_replacement_token'] || '-')
    context.explain { "Using normalized KeyVault secret key for lookup: #{normalized_secret_name}" }
    return Puppet::Pops::Types::PSensitiveType::Sensitive.new(context.cached_value(normalized_secret_name)) if context.cache_has_key(normalized_secret_name)
    access_token = context.cached_value('access_token')
    if access_token.nil?
      metadata_api_version = options['metadata_api_version']
      service_principal_credentials = options['service_principal_credentials']
      if metadata_api_version && service_principal_credentials
        raise ArgumentError, 'metadata_api_version and service_principal_credentials cannot be used together'
      end
      if !metadata_api_version && !service_principal_credentials
        raise ArgumentError, 'must configure at least one of metadata_api_version or service_principal_credentials'
      end

      if service_principal_credentials
        credentials = YAML.load_file(service_principal_credentials)
        access_token = TragicCode::Azure.get_access_token_service_principal(credentials)
      else
        access_token = TragicCode::Azure.get_access_token(metadata_api_version)
      end
      context.cache('access_token', access_token)
    end
    begin
      secret_value = TragicCode::Azure.get_secret(
        options['vault_name'],
        normalized_secret_name,
        options['vault_api_version'],
        access_token,
        '',
      )
    rescue RuntimeError => e
      Puppet.warning(e.message)
      secret_value = nil
    end

    if secret_value.nil?
      context.not_found
      return
    end
    Puppet::Pops::Types::PSensitiveType::Sensitive.new(context.cache(normalized_secret_name, secret_value))
  end
end
