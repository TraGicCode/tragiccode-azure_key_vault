require 'net/http'
require 'json'

# Calls to msi azure agent installed on-prem
module TragicCode
  class AzureOnPrem
    # Note: % is escaped like %%
    AGENT_URL='http://127.0.0.1:40342/metadata/identity/oauth2/token?api-version=%{api_version}&resource=https%%3A%%2F%%2Fvault.azure.net'

    def self.create_request(api_version)
      uri = URI(AGENT_URL % { :api_version => api_version })
      req = Net::HTTP::Get.new(uri.request_uri)
      req['Metadata'] = 'true'
      return uri, req
    end

    def self.get_key_location(api_version)
      uri, req = AzureOnPrem.create_request(api_version)
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      # 403 is expected here. we do not provide ANY key
      raise res.body unless res.is_a?(Net::HTTPUnauthorized)
      raise 'Response header Www-Authenticate is missing' unless res['Www-Authenticate']

      res['Www-Authenticate'].sub(/\s*Basic\s+realm=/,'')
    end

    def self.get_access_token(api_version)
      key_file = AzureOnPrem.get_key_location(api_version)
      raise "Bad key file returned by agent: '#{key_file}'" unless File.exists?(key_file)
      key = File.read(key_file)

      uri, req = AzureOnPrem.create_request(api_version)
      req['Authorization'] = "Basic #{key}"
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      raise res.body unless res.is_a?(Net::HTTPSuccess)
      JSON.parse(res.body)['access_token']
    end

  end
end
