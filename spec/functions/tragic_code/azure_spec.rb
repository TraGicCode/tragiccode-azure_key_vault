require 'spec_helper'

describe TragicCode::Azure do
  context '.normalize_object_name' do
    it 'returns a bearer token' do
      original_var_name = "puppetdb::master::config::puppetdb_server"
      key_replacement_token = "-"

      expected_key_value = "puppetdb--master--config--puppetdb-server"

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
