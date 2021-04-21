require_relative '../../../puppet_x/tragiccode/azure'

Puppet::Functions.create_function(:'azure_key_vault::lookup') do
  dispatch :lookup_key do
    param 'Variant[String, Numeric]', :secret_name
    param 'Struct[{vault_name => String, vault_api_version => String, metadata_api_version => String, key_replacement_token => String}]', :options
    param 'Puppet::LookupContext', :context
  end

  def lookup_key(secret_name, options, context)
    # This is a reserved key name in hiera
    return context.not_found if secret_name == 'lookup_options'
    keyvault_object_name = TragicCode::Azure.normalize_object_name(secret_name, options['key_replacement_token'] || '-')
    return context.cached_value(keyvault_object_name) if context.cache_has_key(keyvault_object_name)
    access_token = if context.cache_has_key('access_token')
                     context.cached_value('access_token')
                   else
                     TragicCode::Azure.get_access_token(options['metadata_api_version'])
                   end
    begin
      secret_value = TragicCode::Azure.get_secret(
        options['vault_name'],
        keyvault_object_name,
        options['vault_api_version'],
        access_token,
        '',
      )
    rescue RuntimeError => e
      Puppet.warning(e.message)
      secret_value = nil
    end
    context.not_found if secret_value.nil?
    return if secret_value.nil?
    context.cache(keyvault_object_name, secret_value)
  end
end
