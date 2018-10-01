require 'open-uri'
require 'json'
require 'puppet'

module TragicCode
  class Azure
    def self.get_access_token(api_version)
      uri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=#{api_version}&resource=https%3A%2F%2Fvault.azure.net"
      token = open(uri, 'Metadata' => 'true')
      JSON.parse(token.string)['access_token']
    end
    def self.get_secret(vault_name, secret_name, vault_api_version, metadata_api_version, secret_version)
      version_parameter = secret_version.empty? ? secret_version : "/#{secret_version}"
      uri = "https://#{vault_name}.vault.azure.net/secrets/#{secret_name}#{version_parameter}?api-version=#{api_version}"
      Puppet.debug("Generated Secrets Url: #{uri}")
      secret = open(uri, 'Authorization' => "Bearer #{get_access_token(metadata_api_version)}")
      JSON.parse(secret.string)['value']
    end
  end
end
