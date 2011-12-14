# Implements the authorize.net specific gateway configuration
module MerchantSidekick
  module Gateways
    class AuthorizeNetGateway < Gateway
      #--- accessors
      cattr_accessor :authorize_net_login_id
      cattr_accessor :authorize_net_transaction_key

      #--- class methods
      class << self 
    
        def config_file_name
          "authorize_net.yml"
        end

        # returns a configuration context read from a yml file in /config
        def config(file_name=nil)
          # Authorize.net configuration
          result = YAML.load_file(RAILS_ROOT + "/config/#{file_name || config_file_name}")[RAILS_ENV].symbolize_keys
          @@authorize_net_login_id = result[:login_id]
          @@authorize_net_transaction_key = result[:transaction_key]
          if result[:mode] == 'test'
            # Tell ActiveMerchant to use the Authorize.net sandbox
            ActiveMerchant::Billing::Base.mode = :test
          end
          result
        end
  
        # returns a gateway instance unless there is one assigned globally from the
        # environment files
        def gateway(file_name=nil)
          unless @@gateway
            authorize_net_config = config(file_name)
            @@gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new({
              :login  => authorize_net_config[:login_id],
              :password => authorize_net_config[:transaction_key]
            }.merge(authorize_net_config[:mode] == 'test' ? { :test => true } : {}))
          end
          @@gateway
        end
  
      end

    end
  end
end