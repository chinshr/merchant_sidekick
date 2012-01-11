# Implements the authorize.net specific gateway configuration
module MerchantSidekick
  module ActiveMerchant
    module Gateways
      class AuthorizeNetGateway < ::MerchantSidekick::ActiveMerchant::Gateways::Base
        class << self

          # Returns an active merchant authorize net gateway instance 
          # unless there is already one assigned.
          def gateway
            unless @@gateway
              ::ActiveMerchant::Billing::Base.mode = :test if config[:mode] == "test"
              @@gateway = ::ActiveMerchant::Billing::AuthorizeNetGateway.new({
                :login    => config[:login_id],
                :password => config[:transaction_key]
              }.merge(config[:mode] == "test" ? {:test => true} : {}))
            end
            @@gateway
          end

        end
      end
    end
  end
end