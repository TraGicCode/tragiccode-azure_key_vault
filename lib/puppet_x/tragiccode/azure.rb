require 'net/http'
require 'json'

module TragicCode
  # Azure API functions
  class Azure
    def self.normalize_object_name(object_name, replacement)
      object_name.gsub(%r{[^0-9a-zA-Z-]}, replacement)
    end

    def self.get_access_token(api_version, identity)
      uri_s = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=#{api_version}&resource=https%3A%2F%2Fvault.azure.net"
      Puppet.debug("get_access_token: specified identity = #{identity}")
      if identity
        if identity.key?('client_id')
          uri_s += "&client_id=#{identity['client_id']}"
          Puppet.debug("set client_id to #{identity['client_id']}")
          Puppet.debug("get_access_token: set uri string to #{uri_s}")
        elsif identity.key?('object_id')
          uri_s += "&object_id=#{identity['object_id']}"
          Puppet.debug("set object_id to #{identity['object_id']}")
          Puppet.debug("get_access_token: set uri string to #{uri_s}")
        else
          Puppet.debug('get_access_token: no explicit identity specified')
        end
      end

      uri = URI(uri_s)
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Metadata'] = 'true'
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end
      raise res.body unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)['access_token']
    end

    def self.get_secret(vault_name, secret_name, vault_api_version, access_token, secret_version)
      version_parameter = secret_version.empty? ? secret_version : "/#{secret_version}"
      uri = URI("https://#{vault_name}.vault.azure.net/secrets/#{secret_name}#{version_parameter}?api-version=#{vault_api_version}")
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Authorization'] = "Bearer #{access_token}"
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req)
      end
      raise res.body unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)['value']
    end
  end
end
