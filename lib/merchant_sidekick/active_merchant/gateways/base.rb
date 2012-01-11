# Implements the base gateway for all active merchant gateways
module MerchantSidekick
  class << self
    
    # Overrides MerchantSidekick::default_gateway setter defined in merchant_sidekick/gateway
    def default_gateway=(value)
      ::MerchantSidekick::ActiveMerchant::Gateways::Base.default_gateway = value
    end
  end

  module ActiveMerchant
    
    module Gateways
      class Base < MerchantSidekick::Gateway
        class << self

          def default_gateway=(value)
            if value.is_a?(Symbol)
              super "::MerchantSidekick::ActiveMerchant::Gateways::#{value.to_s.classify}".constantize.gateway
            else
              super value
            end
          end

        end
      end
    end
  end
end