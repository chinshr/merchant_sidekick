# Implements an outbound invoice.
module MerchantSidekick
  class PurchaseInvoice < Invoice
    belongs_to :purchase_order, :foreign_key => :order_id, :class_name => "MerchantSidekick::PurchaseOrder"
  
    # overrides superclass
    def purchase_invoice?
      true 
    end
  
    # authorizes the payment
    # payment_object is the credit_card instance or other payment objects
    def authorize(payment_object, options={})
      transaction do
        authorization = MerchantSidekick::Payment.class_for(payment_object).authorize(
          gross_total,
          payment_object,
          payment_options(options)
        )
      
        self.push_payment(authorization)

        if authorization.success?
          save(:validate => false)
          payment_authorized!
        else
          # we don't want to save the payment and related objects
          # when the authorization fails
          # transaction_declined!
        end
        authorization
      end
    end

    # Captures a previously authorized payment. If the gross amount of the
    # invoice has changed between authorization and capture, the difference
    # in case authorization amount - capture amount > 0 will be refunded to
    # the respective account, otherwise an exception thrown. 
    # Only payments can be captured, not deposits.
    #
    # E.g.
    #
    #    @order = person.purchase(@product)
    #    @payment = @order.authorize(@credit_card)
    #    ...
    #    @order.capture
    #    @order.invoice.paid? #=> true
    #
    def capture(options={})
      transaction do
        if authorization
          capture_result = authorization.class.capture(
            gross_total,
            authorization_reference,
            payment_options(authorization.content_attributes.merge(options))
          )
        
          self.push_payment(capture_result)

          save(:validate => false)

          if capture_result.success?
            payment_captured!
          else
            transaction_declined!
          end
          capture_result
        end
      end
    end

    # overrides accessor and caches authorization
    def authorization
      @authorization ||= if auth = self.payments.find_by_action_and_success('authorization', true, :order => 'id ASC')
        auth
      elsif auth = self.payments.find_by_action_and_success('purchase', true, :order => 'id ASC')
        auth
      end
    end

    def authorization_reference
      authorization.reference if authorization
    end

    # void a previously authorized payment
    def void(options={})
      transaction do
        if authorization
          void_result = authorization.class.void(
            gross_total,
            authorization_reference,
            payment_options(authorization.content_attributes.merge(options))
          )
          self.push_payment(void_result)

          save(:validate => false)

          if void_result.success?
            payment_voided!
          else
            transaction_declined!
          end
          void_result
        end
      end
    end

    # refunds the entire amount or the amount provided
    # of the invoice
    #
    # Options:
    #   :card_number must be supplied in the options
    #   :amount => specify the amount to be refunded
    #
    def credit(options={})
      transaction do
        if authorization
          credit_result = authorization.class.credit(
            options[:amount] || gross_total,
            authorization_reference,
            payment_options(authorization.content_attributes.merge(options))
          )
          self.push_payment(credit_result)

          save(:validate => false)

          if credit_result.success?
            payment_refunded!
          else
            transaction_declined!
          end
          capture_result
        end
      end
    end

    # Purchase invoice, combines authorization and capture in one step
    def purchase(payment_object, options={})
      transaction do
        purchase_result = MerchantSidekick::Payment.class_for(payment_object).purchase(
          gross_total,
          payment_object,
          payment_options(options)
        )
        self.push_payment(purchase_result)

        save(:validate => false)

        if purchase_result.success?
          payment_paid!
        else
          transaction_declined!
        end
        purchase_result
      end
    end
  
    # returns a hash of additional merchant data passed to authorize
    # you want to pass in the following additional options
    #
    #   :ip => ip address of the buyer
    #   
    def payment_options(options={})
      { # general
        :buyer => self.buyer,
        :seller => self.seller,
        :payable => self,
        # active merchant relevant
        :customer => self.buyer ? "#{self.buyer.name} (#{self.buyer.id})" : nil,
        :email => self.buyer && self.buyer.respond_to?(:email) ? self.buyer.email : nil,
        :invoice => self.number,
        :merchant => self.seller ? "#{self.seller.name} (#{self.seller.id})" : nil,
        :currency => self.currency,
        :billing_address => self.billing_address ? self.billing_address.to_merchant_attributes : nil,
        :shipping_address =>  self.shipping_address ? self.shipping_address.to_merchant_attributes : nil
      }.merge(options)
    end
  
  end
end