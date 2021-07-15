require 'spec_helper'

describe 'azure_key_vault::lookup' do
  let(:options) do
    {
      'vault_name' => 'vault_name',
      'vault_api_version' => 'vault_api_version',
      'metadata_api_version' => 'metadata_api_version',
      'confine_to_keys' => ['^.*sensitive_azure.*'],
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

  it 'accepts 3 required arguments' do
    is_expected.to run.with_params.and_raise_error(ArgumentError, %r{expects 3 arguments}i)
  end
  it 'validates the :options hash' do
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', { 'key1' => 'value1' }, lookup_context
    ).and_raise_error(ArgumentError)
  end
  it 'uses the cache' do
    expect(lookup_context).to receive(:cache_has_key).with('profile--windows--sqlserver--sensitive-azure-sql-user-password').and_return(true)
    expect(lookup_context).to receive(:cached_value).with('profile--windows--sqlserver--sensitive-azure-sql-user-password').and_return('value')
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options, lookup_context
    ).and_return('value')
  end
  it 'caches the access token after a cache miss' do
    access_token_value = 'access_value'
    secret_value = 'secret_value'

    expect(lookup_context).to receive(:cached_value).with('access_token').and_return(nil)
    expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)
    expect(lookup_context).to receive(:cache).with('access_token', access_token_value).ordered
    expect(TragicCode::Azure).to receive(:get_secret).and_return(secret_value)
    expect(lookup_context).to receive(:cache).and_return(secret_value).ordered
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options, lookup_context
    ).and_return(secret_value)
  end

  it 'call context.not_found for the lookup_options key' do
    expect(lookup_context).to receive(:not_found)
    is_expected.to run.with_params(
      'lookup_options', options, lookup_context
    )
  end

  it 'uses - as the default key_replacement_token' do
    secret_name = 'profile::windows::sqlserver::sensitive_azure_sql_user_password'
    access_token_value = 'access_value'
    secret_value = 'secret_value'
    expect(TragicCode::Azure).to receive(:normalize_object_name).with(secret_name, '-')
    expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)
    expect(TragicCode::Azure).to receive(:get_secret).and_return(secret_value)
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options, lookup_context
    ).and_return(secret_value)
  end

  it 'errors when confine_to_keys is no array' do
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'confine_to_keys' => '^vault.*$' }), lookup_context
    ).and_raise_error(ArgumentError, %r{'confine_to_keys' expects an Array value}i)
  end

  it 'errors when passing invalid regexes' do
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'confine_to_keys' => ['['] }), lookup_context
    ).and_raise_error(ArgumentError, %r{creating regexp failed with}i)
  end

  it 'returns the key if regex matches confine_to_keys' do
    access_token_value = 'access_value'
    secret_value = 'secret_value'
    expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)
    expect(TragicCode::Azure).to receive(:get_secret).and_return(secret_value)
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'confine_to_keys' => ['^.*sensitive_azure.*'] }), lookup_context
    ).and_return(secret_value)
  end

  it 'does not return the key if regex does not match confine_to_keys' do
    access_token_value = 'access_value'
    secret_value = 'secret_value'

    expect(lookup_context).to receive(:not_found)
    expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)
    expect(TragicCode::Azure).to receive(:get_secret).and_return(secret_value)

    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_sql_user_password', options.merge({ 'confine_to_keys' => ['^sensitive_azure.*$'] }), lookup_context
    )
  end
end
