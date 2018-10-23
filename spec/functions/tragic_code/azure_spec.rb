require 'spec_helper'

describe TragicCode::Azure do
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
