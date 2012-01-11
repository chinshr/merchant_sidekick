# Implements the Paypal Website Payments Pro specific gateway configuration
#
# development:
#   api_username: seller_xyz_biz_api1.example.com
#   api_password: DMLxxx
#   pem_file_name: dev_cert.txt
#   signature: Aiadlsfsdfdlsfjklsdjf;lasdjfkljsdf;ljlk
#   mode: test
#  ...
#
module MerchantSidekick
  module ActiveMerchant
    module Gateways
      class PaypalGateway < ::MerchantSidekick::ActiveMerchant::Gateways::Base
        class << self

          # Returns an active merchant paypal gateway instance
          #
          # E.g.
          #
          #    # config/active_merchant.yml
          #    development:
          #      api_username: seller_XYZ_biz_api1.example.com
          #      api_password: ABCDEFG123456789
          #      signature: AsPC9BjkCyDFQXbStoZcgqH3hpacAX3IenGazd35.nEnXJKR9nfCmJDu
          #      pem_file_name: config/paypal.pem
          #      mode: test
          #    production:
          #      ...
          #
          def gateway
            unless @@gateway
              options = {
                :login    => config[:api_username],
                :password => config[:api_password]
              }
              options.merge!({:test => true}) if config[:mode] == "test"
              options.merge!({:signature => config[:signature]}) unless config[:signature].blank?
            
              ::ActiveMerchant::Billing::Base.mode = :test if config[:mode] == "test"
              ::ActiveMerchant::Billing::PaypalGateway.pem_file = File.read(File.expand_path(config[:pem_file_name])) if config[:pem_file_name]
              @@gateway = ::ActiveMerchant::Billing::PaypalGateway.new(options)
            end
            @@gateway
          end

        end
      end
    end
  end
end