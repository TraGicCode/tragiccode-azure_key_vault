require_relative '../../../puppet_x/tragiccode/azure'

Puppet::Functions.create_function(:'azure_key_vault::lookup') do
  dispatch :lookup_key do
    param 'Variant[String, Numeric]', :secret_name
    param 'Struct[{
      vault_name => String,
      vault_api_version => String,
      Optional[metadata_api_version] => String,
      confine_to_keys => Array[String],
      Optional[strip_from_keys] => Array[String],
      Optional[key_replacement_token] => String,
      Optional[service_principal_credentials] => String,
      Optional[use_azure_arc_authentication] => Boolean,
      Optional[prefixes] => Array[String],
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

    prefixes = options['prefixes']
    if prefixes
      raise ArgumentError, 'prefixes must be an array' unless prefixes.is_a?(Array)
    end

    strip_from_keys = options['strip_from_keys']
    if strip_from_keys
      raise ArgumentError, 'strip_from_keys must be an array' unless strip_from_keys.is_a?(Array)

      strip_from_keys.each do |prefix|
        secret_name_before_strippers = secret_name
        regex = Regexp.new(prefix)
        if secret_name.match?(regex)
          secret_name = secret_name.gsub(regex, '')
          context.explain { "Stripping the following pattern of #{prefix} from secret_name.  The stripped secret_name has now changed from #{secret_name_before_strippers} to #{secret_name}" }
        end
      end
    end

    key_replacement_token = options['key_replacement_token'] || '-'
    if prefixes
      normalized_prefixed_keys = prefixes.map { |prefix| TragicCode::Azure.normalize_object_name(prefix + secret_name, key_replacement_token) }
      normalized_prefixed_keys.each do |normalized_prefixed_key|
        return Puppet::Pops::Types::PSensitiveType::Sensitive.new(context.cached_value(normalized_prefixed_key)) if context.cache_has_key(normalized_prefixed_key)
      end
    else
      normalized_secret_name = TragicCode::Azure.normalize_object_name(secret_name, key_replacement_token)
      context.explain { "Using normalized KeyVault secret key for lookup: #{normalized_secret_name}" }
      return Puppet::Pops::Types::PSensitiveType::Sensitive.new(context.cached_value(normalized_secret_name)) if context.cache_has_key(normalized_secret_name)
    end
    access_token = context.cached_value('access_token')
    if access_token.nil?
      metadata_api_version = options['metadata_api_version']
      service_principal_credentials = options['service_principal_credentials']
      use_azure_arc_authentication = options['use_azure_arc_authentication']

      if metadata_api_version && service_principal_credentials
        raise ArgumentError, 'metadata_api_version and service_principal_credentials cannot be used together'
      end
      if !metadata_api_version && !service_principal_credentials
        raise ArgumentError, 'must configure at least one of metadata_api_version or service_principal_credentials'
      end

      if service_principal_credentials
        credentials = YAML.load_file(service_principal_credentials)
        access_token = TragicCode::Azure.get_access_token_service_principal(credentials)
      elsif use_azure_arc_authentication
        access_token = TragicCode::Azure.get_access_token_azure_arc(metadata_api_version)
      else
        access_token = TragicCode::Azure.get_access_token(metadata_api_version)
      end
      context.cache('access_token', access_token)
    end
    secret_value = nil
    begin
      if normalized_prefixed_keys
        normalized_prefixed_keys.each do |normalized_prefixed_secret_key|
          secret_value = TragicCode::Azure.get_secret(
            options['vault_name'],
            normalized_prefixed_secret_key,
            options['vault_api_version'],
            access_token,
            '',
          )
          break unless secret_value.nil?
        end
      else
        secret_value = TragicCode::Azure.get_secret(
          options['vault_name'],
          normalized_secret_name,
          options['vault_api_version'],
          access_token,
          '',
        )
      end
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
