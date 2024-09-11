require 'net/http'
require 'json'

module TragicCode
  # Azure API functions
  class Azure
    @@AZURE_ARC_INSTANCE_METADATA_ENPOINT_IP = '127.0.0.1'.freeze

    def self.normalize_object_name(object_name, replacement)
      object_name.gsub(%r{[^0-9a-zA-Z-]}, replacement)
    end

    def self.get_access_token_azure_arc(api_version)
      # Generate File and Read Challenge Token
      uri = URI("http://#{@@AZURE_ARC_INSTANCE_METADATA_ENPOINT_IP}/metadata/identity/oauth2/token?api-version=#{api_version}&resource=https%3A%2F%2Fvault.azure.net")
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Metadata'] = 'true'
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      # 403 is expected here. we do not provide ANY key
      raise res.body unless res.is_a?(Net::HTTPUnauthorized)
      raise 'Response header Www-Authenticate is missing' unless res['Www-Authenticate']

      challenge_token_file_path = res['Www-Authenticate'].sub(%r{\s*Basic\s+realm=}, '')
      challenge_token = File.read(challenge_token_file_path)

      # Get Access Token using challenge token
      internal_get_access_token(api_version, @@AZURE_ARC_INSTANCE_METADATA_ENPOINT_IP, { 'Authorization' => "Basic #{challenge_token}" })
    end

    def self.get_access_token(api_version)
      internal_get_access_token(api_version, '169.254.169.254')
    end

    def self.internal_get_access_token(api_version, instance_metadata_service_endpoint = '169.254.169.254', extra_http_headers_hash = {})
      uri = URI("http://#{instance_metadata_service_endpoint}/metadata/identity/oauth2/token?api-version=#{api_version}&resource=https%3A%2F%2Fvault.azure.net")
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Metadata'] = 'true'
      extra_http_headers_hash.each do |key, value|
        req[key] = value
      end
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end
      raise res.body unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)['access_token']
    end

    def self.get_access_token_service_principal(credentials)
      uri = URI("https://login.microsoftonline.com/#{credentials.fetch('tenant_id')}/oauth2/v2.0/token")
      data = {
        'grant_type': 'client_credentials',
        'client_id': credentials.fetch('client_id'),
        'client_secret': credentials.fetch('client_secret'),
        'scope': 'https://vault.azure.net/.default'
      }
      req = Net::HTTP::Post.new(uri.request_uri)
      res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(req, URI.encode_www_form(data))
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
      return nil if res.is_a?(Net::HTTPNotFound)
      raise res.body unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)['value']
    end
  end
end
