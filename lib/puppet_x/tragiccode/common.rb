module TragicCode

  class Helpers

    def self.validate_optional_exclusive_args(*args)
      args_cnt = args.count{|el| !el.nil? }

      if args_cnt > 1
        raise ArgumentError, 'Use only one of metadata_api_version, service_principal_credentials or onprem_agent_api_version'
      end

      if args_cnt == 0
        raise ArgumentError, 'must configure at least one of metadata_api_version, service_principal_credentials or onprem_agent_api_version'
      end
    end
  end
end
