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

  it { is_expected.not_to eq(nil) }

  context 'when passed the wrong number of arguments' do
    it { is_expected.to run.with_params.and_raise_error(ArgumentError, %r{expects between 3 and 4 arguments}i) }
  end

  context 'when getting the latest version of a secret' do
    it 'defaults to using an empty string as the latest version' do
      expect(TragicCode::Azure).to receive(:get_access_token).with(api_versions_hash['metadata_api_version']).and_return(access_token)
      expect(TragicCode::Azure).to receive(:get_secret).with(vault_name, secret_name, api_versions_hash['vault_api_version'], access_token, '')

      is_expected.to run.with_params(vault_name, secret_name, api_versions_hash)
    end
  end

  context 'when getting a specific version of a secret' do
    it 'uses the secret version when retreiving the secret' do
      expect(TragicCode::Azure).to receive(:get_access_token).with(api_versions_hash['metadata_api_version']).and_return(access_token)
      expect(TragicCode::Azure).to receive(:get_secret).with(vault_name, secret_name, api_versions_hash['vault_api_version'], access_token, secret_version)

      is_expected.to run.with_params(vault_name, secret_name, api_versions_hash, secret_version)
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
end
