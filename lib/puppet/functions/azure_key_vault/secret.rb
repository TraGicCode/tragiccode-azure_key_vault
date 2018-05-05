require 'open-uri'
require 'json'

Puppet::Functions.create_function(:'azure_key_vault::secret') do
  dispatch :secret do
    required_param 'String', :vault_name
    required_param 'String', :secret_name
    required_param 'Hash',   :api_versions_hash
    optional_param 'String', :secret_version
  end

  def secret(vault_name, secret_name, api_versions_hash, secret_version = '')
    Puppet.info("vault_base_url: #{vault_name}")
    Puppet.info("secret_name: #{secret_name}")
    Puppet.info("secret_version: #{secret_version}")
    Puppet.info("metadata_api_version: #{api_versions_hash['metadata_api_version']}")
    Puppet.info("api_version_vault: #{api_versions_hash['vault_api_version']}")

    secret_url = "https://#{vault_name}.vault.azure.net/secrets/#{secret_name}#{secret_version.empty? ? secret_version : "/#{secret_version}"}?api-version=#{api_versions_hash['vault_api_version']}"
    Puppet.info("Generated Secrets Url: #{secret_url}")

    # Get MSI's Access-Token
    get_access_token = open("http://169.254.169.254/metadata/identity/oauth2/token?api-version=#{api_versions_hash['metadata_api_version']}&resource=https%3A%2F%2Fvault.azure.net", 'Metadata' => 'true')
    access_token = JSON.parse(get_access_token.string)['access_token']
    get_secret = open(secret_url, 'Authorization' => "Bearer #{access_token}")
    secret_value = JSON.parse(get_secret.string)['value']
    Puppet::Pops::Types::PSensitiveType::Sensitive.new(secret_value)
  end
end
