require_relative '../../../puppet_x/tragiccode/azure'

Puppet::Functions.create_function(:'azure_key_vault::lookup') do
  dispatch :lookup_key do
    param 'Variant[String, Numeric]', :secret_name
    param 'Struct[{vault_name => String, vault_api_version => String, metadata_api_version => String}]', :options
    param 'Puppet::LookupContext', :context
  end

  def lookup_key(secret_name, options, context)
    return context.cached_value(secret_name) if context.cache_has_key(secret_name)
    begin
      secret_value = TragicCode::Azure.get_secret(
        options['vault_name'],
        secret_name,
        options['vault_api_version'],
        options['metadata_api_version'],
        ''
      )
    rescue => e
      Puppet.warn(e)
      secret_value = nil
    end
    if secret_value.nil?
      context.not_found()
      return
    end
    return context.cache(secret_name, secret_value)
  end
end
