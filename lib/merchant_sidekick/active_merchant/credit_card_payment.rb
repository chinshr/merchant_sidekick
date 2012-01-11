# This class handles all credit card payment transactions using ActiveMerchant.
module MerchantSidekick
  module ActiveMerchant
    class CreditCardPayment < Payment
      cattr_accessor :gateway
      serialize :params

      class << self

        # Returns an active merchant gateway instance, based on the following:
        #
        #   * an active merchant gateway instance assigned to the gateway
        #     class accessor
        #   * a merchant sidekick specific gateway identifier, 
        #     e.g. :authorize_net_gateway, is passed into the gateway class accessor
        #   * otherwise falls back to the default gateway assigned as
        #     MerchantSidekick::Gateways::Gateway.default_gateway
        #
        # Declare as needed in the environment.
        #
        # E.g.
        #
        #   CreditCardPayment.gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new({
        #     :login    => @login_id,
        #     :password => @transaction_key
        #   })
        #
        #   or
        #
        #   CreditCardPayment.gateway = :authorize_net_gateway
        #
        def gateway
          if @@gateway.is_a? ::ActiveMerchant::Billing::Gateway
            @@gateway
          elsif @@gateway.is_a? Symbol
            @@gateway = "::MerchantSidekick::ActiveMerchant::Gateways::#{@@gateway.to_s.classify}".constantize.gateway
            @@gateway
          else
            @@gateway = MerchantSidekick::Gateway.default_gateway
          end
        end

        def authorize(amount, credit_card, options = {})
          process('authorization', amount, options) do |gw|
            gw.authorize(amount.cents, credit_card, options)
          end
        end

        def capture(amount, authorization, options = {})
          process('capture', amount, options) do |gw|
            gw.capture(amount.cents, authorization, options)
          end
        end

        def purchase(amount, credit_card, options = {})
          process('purchase', amount, options) do |gw|
            gw.purchase(amount.cents, credit_card, options)
          end
        end

        def void(amount, authorization, options = {})
          process('void', amount, options) do |gw|
            gw.void(authorization, options)
          end
        end

        # requires :card_number option
        def credit(amount, authorization, options = {})
          process('credit', amount, options) do |gw|
            gw.credit(amount.cents, authorization, options)
          end
        end

        # works with paypal payflow
        def transfer(amount, destination_account, options={})
          process('transfer', amount, options) do |gw|
            gw.transfer(amount.cents, destination_account, options)
          end
        end

        private

        def process(action, amount = nil, options = {})
          result = CreditCardPayment.new
          result.amount = amount
          result.action = action

          begin
            options[:currency] = amount.currency if amount.respond_to?(:currency)
            response = yield gateway

            result.success   = response.success?
            result.reference = response.authorization
            result.message   = response.message
            result.params    = response.params
            result.test      = response.test?
          rescue ::ActiveMerchant::ActiveMerchantError => e
            result.success   = false
            result.reference = nil
            result.message   = e.message
            result.params    = {}
            result.test      = gateway.test?
          end
          result
        end
      end

      #--- instance methods

      # override in sublcass
      def payment_type
        :credit_card
      end

    end
  end
end