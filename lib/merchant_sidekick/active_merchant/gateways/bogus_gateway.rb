# Implements the bogus gatway active merchant gateway wrapper
module MerchantSidekick
  module ActiveMerchant
    module Gateways
      class BogusGateway < ::MerchantSidekick::ActiveMerchant::Gateways::Base
        class << self

          def gateway
            unless @@gateway
              @@gateway = ::ActiveMerchant::Billing::BogusGateway.new
            end
            @@gateway
          end

        end
      end
    end
  end
end