require 'spec_helper'

describe 'azure_key_vault::secret' do
  let(:api_versions_hash) do
    {
      'metadata_api_version' => 'test',
      'vault_api_version' => 'test',
    }
  end

  let(:vault_name) { 'production-vault' }
  let(:secret_name) { 'super-secret' }
  let(:secret_value) { 'super-secret-value' }
  let(:access_token) { 'random-access-token' }
  let(:secret_version) { 'a7f7es9a7d' }

  PuppetSensitive = Puppet::Pops::Types::PSensitiveType::Sensitive

  it { is_expected.not_to eq(nil) }

  context 'when passed the wrong arguments' do
    it 'errors when wrong number of arguments' do
      is_expected.to run.with_params.and_raise_error(ArgumentError, %r{expects between 3 and 4 arguments}i)
    end

    it "errors when using both 'metadata_api_version' and 'service_principal_credentials'" do
      bad_hash = {
        'metadata_api_version' => 'test',
        'vault_api_version' => 'test',
        'service_principal_credentials' => {
          'tenant_id' => 'test_tenant',
          'client_id' => 'test_client',
          'client_secret' => 'test_secret'
        }
      }
      is_expected.to run.with_params(
        vault_name, secret_name, bad_hash
      ).and_raise_error(%r{metadata_api_version and service_principal_credentials cannot be used together})
    end

    it "errors when missing both 'metadata_api_version' and 'service_principal_credentials'" do
      bad_hash = api_versions_hash
      bad_hash.delete('metadata_api_version')
      is_expected.to run.with_params(
        vault_name, secret_name, bad_hash
      ).and_raise_error(%r{hash must contain at least one of metadata_api_version or service_principal_credentials})
    end
  end

  context 'when getting the latest version of a secret' do
    it 'defaults to using an empty string as the latest version' do
      expect(TragicCode::Azure).to receive(:get_access_token).with(api_versions_hash['metadata_api_version']).and_return(access_token)
      expect(TragicCode::Azure).to receive(:get_secret).with(vault_name, secret_name, api_versions_hash['vault_api_version'], access_token, '').and_return(secret_value)

      is_expected.to run.with_params(vault_name, secret_name, api_versions_hash)
    end
  end

  context 'when getting a specific version of a secret' do
    it 'uses the secret version when retreiving the secret' do
      expect(TragicCode::Azure).to receive(:get_access_token).with(api_versions_hash['metadata_api_version']).and_return(access_token)
      expect(TragicCode::Azure).to receive(:get_secret).with(vault_name, secret_name, api_versions_hash['vault_api_version'], access_token, secret_version).and_return(secret_value)

      is_expected.to run.with_params(vault_name, secret_name, api_versions_hash, secret_version)
    end
  end

  context 'when getting a secret that does not exist in the vault' do
    it 'throws an error' do
      expect(TragicCode::Azure).to receive(:get_access_token).with(api_versions_hash['metadata_api_version']).and_return(access_token)
      expect(TragicCode::Azure).to receive(:get_secret).with(vault_name, secret_name, api_versions_hash['vault_api_version'], access_token, secret_version).and_return(nil)

      is_expected.to run.with_params(
        vault_name, secret_name, api_versions_hash, secret_version
      ).and_raise_error(Puppet::Error, %r{The secret named #{secret_name} could not be found in a vault named #{vault_name}}i)
    end
  end

  # rubocop:disable RSpec/NamedSubject
  it 'returns the secret' do
    expect(TragicCode::Azure).to receive(:get_access_token).with(api_versions_hash['metadata_api_version']).and_return(access_token)
    expect(TragicCode::Azure).to receive(:get_secret).with(vault_name, secret_name, api_versions_hash['vault_api_version'], access_token, '').and_return(secret_value)

    expect(subject.execute(vault_name, secret_name, api_versions_hash).unwrap).to eq secret_value
  end

  it 'returns the secret wrapped in the sensitive data type' do
    expect(TragicCode::Azure).to receive(:get_access_token).with(api_versions_hash['metadata_api_version']).and_return(access_token)
    expect(TragicCode::Azure).to receive(:get_secret).with(vault_name, secret_name, api_versions_hash['vault_api_version'], access_token, '').and_return(secret_value)

    expect(subject.execute(vault_name, secret_name, api_versions_hash)).to be_an_instance_of(Puppet::Pops::Types::PSensitiveType::Sensitive)
  end
  # rubocop:enable RSpec/NamedSubject

  # rubocop:disable RSpec/NamedSubject
  it 'retrieves access_token from cache' do
    expect(TragicCode::Azure).to receive(:get_access_token).with(api_versions_hash['metadata_api_version']).and_return(access_token).once
    expect(TragicCode::Azure).to receive(:get_secret).with(vault_name, secret_name, api_versions_hash['vault_api_version'], access_token, '').and_return(secret_value).twice

    subject.execute(vault_name, secret_name, api_versions_hash)
    subject.execute(vault_name, secret_name, api_versions_hash)
  end
  # rubocop:enable RSpec/NamedSubject

  context 'authenticating with service principal' do
    let(:api_versions_hash) do
      {
        'vault_api_version' => 'test_version',
        'service_principal_credentials' => {
          'tenant_id' => 'test_tenant',
          'client_id' => 'test_client',
          'client_secret' => 'test_secret'
        }
      }
    end

    it 'returns the secret' do
      expect(TragicCode::Azure).to receive(:get_access_token_service_principal).with(api_versions_hash['service_principal_credentials']).and_return(access_token)
      expect(TragicCode::Azure).to receive(:get_secret).with(vault_name, secret_name, api_versions_hash['vault_api_version'], access_token, '').and_return(secret_value)

      is_expected.to run.with_params(vault_name, secret_name, api_versions_hash).and_return(PuppetSensitive.new(secret_value))
    end

    # rubocop:disable RSpec/NamedSubject
    it 'retrieves access_token from cache' do
      expect(TragicCode::Azure).to receive(:get_access_token_service_principal).and_return(access_token).once
      expect(TragicCode::Azure).to receive(:get_secret).and_return(secret_value).twice

      subject.execute(vault_name, secret_name, api_versions_hash)
      subject.execute(vault_name, secret_name, api_versions_hash)
    end
    # rubocop:enable RSpec/NamedSubject
  end
end
