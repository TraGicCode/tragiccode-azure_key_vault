require 'spec_helper'

describe 'azure_key_vault::secret' do
  let(:api_versions_hash) do
    {
      'metadata_api_version' => 'test',
      'vault_api_version' => 'test',
    }
  end

  it { is_expected.not_to eq(nil) }

  context 'when passed the wrong number of arguments' do
    it { is_expected.to run.with_params.and_raise_error(ArgumentError, %r{expects between 3 and 4 arguments}i) }
  end

  context 'when getting the latest version of a secret' do
    # it { is_expected.to run.with_params('production-vault', 'super-secret', api_versions_hash).and_return('https://production-vault.vault.azure.net/secrets/super-secret') }
    pending
  end

  context 'when getting a specific version of a secret' do
    pending
  end

  context 'when passing a malformed api-version' do
    pending
  end
end
