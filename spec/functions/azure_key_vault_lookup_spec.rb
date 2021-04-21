require 'spec_helper'

describe 'azure_key_vault::lookup' do
  let(:options) do
    {
      'vault_name' => 'vault_name',
      'vault_api_version' => 'vault_api_version',
      'metadata_api_version' => 'metadata_api_version',
      'key_replacement_token' => '-',
    }
  end
  let(:lookup_context) do
    environment = instance_double('environment')
    allow(environment).to receive(:name).and_return('production')
    invocation = Puppet::Pops::Lookup::Invocation.new(nil)
    environment_context = Puppet::Pops::Lookup::EnvironmentContext.create_adapter(environment)
    function_context = Puppet::Pops::Lookup::FunctionContext.new(
      environment_context,
      nil,
      'the_function',
    )
    Puppet::Pops::Lookup::Context.new(function_context, invocation)
  end

  it { is_expected.not_to eq(nil) }

  it 'only accepts 3 arguments' do
    is_expected.to run.with_params.and_raise_error(ArgumentError, %r{expects 3 arguments}i)
  end
  it 'validates the :options hash' do
    is_expected.to run.with_params(
      'secret_name', { 'key1' => 'value1' }, lookup_context
    ).and_raise_error(ArgumentError)
  end
  it 'uses the cache' do
    expect(lookup_context).to receive(:cache_has_key).with('secret-name').and_return(true)
    expect(lookup_context).to receive(:cached_value).with('secret-name').and_return('value')
    is_expected.to run.with_params(
      'secret_name', options, lookup_context
    ).and_return('value')
  end

  it 'call context.not_found for the lookup_options key' do
    expect(lookup_context).to receive(:not_found)
    is_expected.to run.with_params(
      'lookup_options', options, lookup_context
    )
  end
end
