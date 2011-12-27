# Implements inbound invoices, i.e. the merchant sells a product to a client.
module MerchantSidekick
  class SalesInvoice < Invoice
    #--- associations
    #has_many :sales_orders, :class_name => "MerchantSidekick::SalesOrder"
  
    #--- instance methods
  
    def sales_invoice?
      true 
    end
  
    # cash invoice, combines authorization and capture in one step
    def cash(payment_object, options={})
      transaction do
        cash_result = MerchantSidekick::Payment.class_for(payment_object).transfer(
          gross_total,
          payment_object,
          payment_options(options)
        )
        self.push_payment(cash_result)

        save(:validate => false)

        if cash_result.success?
          payment_paid!
        else
          transaction_declined!
        end
        cash_result
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
        :customer => "#{self.seller.name} (#{self.seller.id})",
        :email => self.seller && self.seller.respond_to?(:email) ? self.seller.email : nil,
        :invoice => self.number,
        :merchant => self.buyer ? "#{self.buyer.name} (#{self.buyer.id})" : nil,
        :currency => self.currency,
        :billing_address => self.billing_address ? self.billing_address.to_merchant_attributes : nil,
        :shipping_address =>  self.shipping_address ? self.shipping_address.to_merchant_attributes : nil
      }.merge(options)
    end
  
  end
end