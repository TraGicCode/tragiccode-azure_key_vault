require 'spec_helper'

describe TragicCode::Azure do
  context '.normalize_object_name' do
    it 'returns a bearer token' do
      original_var_name = 'puppetdb::master::config::puppetdb_server'
      key_replacement_token = '-'

      expected_key_value = 'puppetdb--master--config--puppetdb-server'

      expect(described_class.normalize_object_name(original_var_name, key_replacement_token)).to eq(expected_key_value)
    end
  end

  context '.get_access_token' do
    it 'returns a bearer token' do
      stub_request(:get, %r{169.254.169.254})
        .to_return(body: '{"access_token": "token"}', status: 200)
      expect(described_class.get_access_token('api')).to eq('token')
    end
    it 'errors when the response is not 2xx' do
      stub_request(:get, %r{169.254.169.254})
        .to_return(body: 'some_error', status: 400)
      expect { described_class.get_access_token('api') }.to raise_error('some_error')
    end
  end

  context '.get_access_token_azure_arc' do
    it 'returns a bearer token' do
      File.stub(:read).and_return('magical-token-from-file')

      stub_request(:get, %r{127.0.0.1})
        .to_return(
          body: '{"access_token": "token"}',
          status: 401,
          headers: { 'Www-Authenticate' => 'Basic realm=C:\\ProgramData\\AzureConnectedMachineAgent\\Tokens\\f1da0584-97f4-42fd-a671-879ad3de86fa.key' },
        )

      stub_request(:get, %r{127.0.0.1})
        .with(headers: { 'Authorization' => 'Basic magical-token-from-file' })
        .to_return(body: '{"access_token": "token"}', status: 200)

      expect(described_class.get_access_token_azure_arc('api')).to eq('token')
    end

    it 'throws error with response body when response is not 401 (unauthorized) when attempting to generate secret file' do
      stub_request(:get, %r{127.0.0.1})
        .to_return(body: 'some_error', status: 200)
      expect { described_class.get_access_token_azure_arc('api') }.to raise_error('some_error')
    end

    it 'throws error when the 401 (unauthorized) response is missing the Www-Authenticate header' do
      stub_request(:get, %r{127.0.0.1})
        .to_return(body: 'some_error', status: 401)
      expect { described_class.get_access_token_azure_arc('api') }.to raise_error('Response header Www-Authenticate is missing')
    end

    it 'throws error with response body when response is not 2xx when getting the auth token' do
      File.stub(:read).and_return('magical-token-from-file')
      # rubocop:disable Layout/LineLength
      stub_request(:get, %r{127.0.0.1})
        .to_return(body: '{"access_token": "token"}', status: 401, headers: { 'Www-Authenticate' => 'Basic realm=C:\\ProgramData\\AzureConnectedMachineAgent\\Tokens\\f1da0584-97f4-42fd-a671-879ad3de86fa.key' })
      # rubocop:enable Layout/LineLength
      stub_request(:get, %r{127.0.0.1})
        .with(headers: { 'Authorization' => 'Basic magical-token-from-file' })
        .to_return(body: 'some_error', status: 400)

      expect { described_class.get_access_token_azure_arc('api') }.to raise_error('some_error')
    end
  end

  context '.get_access_token_service_principal' do
    let(:credentials) { { 'client_id' => '', 'tenant_id' => '', 'client_secret' => '' } }

    it 'returns a bearer token' do
      stub_request(:post, %r{login.microsoftonline.com})
        .to_return(body: '{"access_token": "token"}', status: 200)
      expect(described_class.get_access_token_service_principal(credentials)).to eq('token')
    end
    it 'errors when the response is not 2xx' do
      stub_request(:post, %r{login.microsoftonline.com})
        .to_return(body: 'some_error', status: 400)
      expect { described_class.get_access_token_service_principal(credentials) }.to raise_error('some_error')
    end
  end

  context '.get_secret' do
    it 'returns a secret' do
      vault_name = 'vault'
      stub_request(:get, %r{vault}i)
        .to_return(body: '{"value": "secret"}', status: 200)
      expect(described_class.get_secret(vault_name, 'secret_name', 'api', 'token', '')).to eq('secret')
    end
    it 'errors when the response is not 2xx' do
      vault_name = 'vault'
      stub_request(:get, %r{vault}i)
        .to_return(body: 'some_error', status: 400)
      expect { described_class.get_secret(vault_name, 'secret_name', 'api', 'token', '') }.to raise_error('some_error')
    end
  end
end
