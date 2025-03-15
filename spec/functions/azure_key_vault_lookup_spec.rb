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

  # rubocop:disable RSpec/NamedSubject
  it 'uses the cache' do
    expect(lookup_context).to receive(:cache_has_key).with('profile--windows--sqlserver--sensitive-azure-sql-user-password').and_return(true)
    expect(lookup_context).to receive(:cached_value).with('profile--windows--sqlserver--sensitive-azure-sql-user-password').and_return('value')

    expect(subject.execute('profile::windows::sqlserver::sensitive_azure_sql_user_password', options, lookup_context).unwrap).to eq 'value'
  end

  # rubocop:enable RSpec/NamedSubject

  # rubocop:disable RSpec/NamedSubject
  it 'caches the access token after a cache miss' do
    access_token_value = 'access_value'
    secret_value = 'secret_value'

    expect(lookup_context).to receive(:cached_value).with('access_token').and_return(nil)
    expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)
    expect(lookup_context).to receive(:cache).with('access_token', access_token_value).ordered
    expect(TragicCode::Azure).to receive(:get_secret).and_return(secret_value)
    expect(lookup_context).to receive(:cache).and_return(secret_value).ordered

    expect(subject.execute('profile::windows::sqlserver::sensitive_azure_sql_user_password', options, lookup_context).unwrap).to eq secret_value
  end
  # rubocop:enable RSpec/NamedSubject

  it 'call context.not_found for the lookup_options key' do
    expect(lookup_context).to receive(:not_found)
    is_expected.to run.with_params(
      'lookup_options', options, lookup_context
    )
  end

  # rubocop:disable RSpec/NamedSubject
  it "uses '-' as the default key_replacement_token" do
    secret_name = 'profile::windows::sqlserver::sensitive_azure_sql_user_password'
    access_token_value = 'access_value'
    secret_value = 'secret_value'
    expect(TragicCode::Azure).to receive(:normalize_object_name).with(secret_name, '-')
    expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)
    expect(TragicCode::Azure).to receive(:get_secret).and_return(secret_value)

    expect(subject.execute('profile::windows::sqlserver::sensitive_azure_sql_user_password', options, lookup_context).unwrap).to eq secret_value
  end
  # rubocop:enable RSpec/NamedSubject

  it 'errors when confine_to_keys is no array' do
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'confine_to_keys' => '^vault.*$' }), lookup_context
    ).and_raise_error(ArgumentError, %r{'confine_to_keys' expects an Array value}i)
  end

  it 'errors when strip_from_keys is no array' do
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'strip_from_keys' => '^vault.*$' }), lookup_context
    ).and_raise_error(ArgumentError, %r{'strip_from_keys' expects an Array value}i)
  end

  it "errors when using both 'metadata_api_version' and 'service_principal_credentials'" do
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'service_principal_credentials' => 'path' }), lookup_context
    ).and_raise_error(ArgumentError, %r{metadata_api_version and service_principal_credentials cannot be used together}i)
  end

  it "errors when missing both 'metadata_api_version' and 'service_principal_credentials'" do
    bad_options = options
    bad_options.delete('metadata_api_version')
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', bad_options, lookup_context
    ).and_raise_error(ArgumentError, %r{must configure at least one of metadata_api_version or service_principal_credentials}i)
  end

  it 'errors when passing invalid regexes' do
    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'confine_to_keys' => ['['] }), lookup_context
    ).and_raise_error(ArgumentError, %r{creating regexp failed with}i)
  end

  # rubocop:disable RSpec/NamedSubject
  it 'returns the key if regex matches confine_to_keys' do
    access_token_value = 'access_value'
    secret_value = 'secret_value'
    expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)
    expect(TragicCode::Azure).to receive(:get_secret).and_return(secret_value)

    expect(subject.execute('profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'confine_to_keys' => ['^.*sensitive_azure.*'] }), lookup_context).unwrap)
      .to eq secret_value
  end
  # rubocop:enable RSpec/NamedSubject

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

  describe 'strip_from_keys' do
    [
      {
        input_secret_name: 'profile::windows::sqlserver::azure_sql_user_password',
        expected_secret_name: 'profile--windows--sqlserver--sql-user-password',
        secret_value: 'secret_value',
        strip_from_keys: ['azure_'],
        confine_to_keys: ['^.*azure_.*']
      },
      {
        input_secret_name: 'profile::windows::sqlserver::azure_sql_user_password',
        expected_secret_name: 'azure-sql-user-password',
        secret_value: 'secret_value',
        strip_from_keys: ['^profile::.*::'],
        confine_to_keys: ['^.*azure_.*']
      },
    ].each do |test_case|
      it "strips the patterns #{test_case[:strip_from_keys]} from the secret_name changing it from #{test_case[:input_secret_name]} to #{test_case[:expected_secret_name]}" do
        access_token_value = 'access_value'

        expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)

        expect(TragicCode::Azure).to receive(:get_secret).with(
          options['vault_name'],
          test_case[:expected_secret_name],
          options['vault_api_version'],
          access_token_value,
          '',
        ).and_return(test_case[:secret_value])

        # rubocop:disable RSpec/NamedSubject
        expect(subject.execute(
          test_case[:input_secret_name],
          options.merge({
                          'confine_to_keys' => test_case[:confine_to_keys],
            'strip_from_keys' => test_case[:strip_from_keys]
                        }),
          lookup_context,
        ).unwrap).to eq test_case[:secret_value]
        # rubocop:enable RSpec/NamedSubject
      end
    end
  end

  it 'calls context.not_found when secret is not found in vault' do
    access_token_value = 'access_value'

    expect(lookup_context).to receive(:not_found)
    expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)
    expect(TragicCode::Azure).to receive(:get_secret).and_return(nil)

    is_expected.to run.with_params(
      'profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'confine_to_keys' => ['^.*sensitive_azure.*'] }), lookup_context
    )
  end

  # rubocop:disable RSpec/NamedSubject
  it 'returns the secret wrapped in the sensitive data type' do
    access_token_value = 'access_value'
    secret_value = 'secret_value'
    expect(TragicCode::Azure).to receive(:get_access_token).and_return(access_token_value)
    expect(TragicCode::Azure).to receive(:get_secret).and_return(secret_value)

    expect(subject.execute('profile::windows::sqlserver::sensitive_azure_sql_user_password', options.merge({ 'confine_to_keys' => ['^.*sensitive_azure.*'] }), lookup_context))
      .to be_an_instance_of(Puppet::Pops::Types::PSensitiveType::Sensitive)
  end
  # rubocop:enable RSpec/NamedSubject
end
