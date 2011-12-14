# Implements inbound orders, i.e. when merchant sells a product.
module MerchantSidekick
  class SalesOrder < Order
    belongs_to :sales_invoice, :foreign_key => :invoice_id
  
    # Cash the order and generate invoice
    def cash(payment_object, options={})
      defaults = { :order_id => number }
      options = defaults.merge(options).symbolize_keys

      # before_payment
      seller.send( :before_payment, self ) if seller && seller.respond_to?( :before_payment )
    
      self.build_addresses
      self.build_invoice unless self.invoice
    
      payment = self.invoice.cash(payment_object, options)
      if payment.success?
        process_payment!
        approve_payment!
      end

      # after_payment
      buyer.send( :after_payment, self ) if buyer && buyer.respond_to?( :after_payment )
      payment
    end
  
    def sales_order?
      true
    end
  
    # used in build_invoice to determine which type of invoice
    def to_invoice_class_name
      'SalesInvoice'
    end
  
    def invoice
      self.sales_invoice
    end
  
    def invoice=(an_invoice)
      self.sales_invoice = an_invoice
    end
  
    def build_invoice #:nodoc:
      new_invoice = self.build_sales_invoice( 
        :line_items => self.line_items,
        :net_amount => self.net_total,
        :tax_rate => self.tax_rate,
        :tax_amount => self.tax_total,
        :gross_amount => self.gross_total,
        :buyer => self.buyer,
        :seller => self.seller,
        :origin_address => self.origin_address ? self.origin_address.clone : nil,
        :billing_address => self.billing_address ? self.billing_address.clone : nil,
        :shipping_address => self.shipping_address ? self.shipping_address.clone : nil
      )
    
      # set new invoice's line items to invoice we just created
      new_invoice.line_items.each do |li|
        if li.new_record?
          li.invoice = new_invoice
        else
          li.update_attribute(:invoice, new_invoice)
        end
      end
    
      # copy addresses
      new_invoice.build_origin_address(self.origin_address.content_attributes) if self.origin_address
      new_invoice.build_billing_address(self.billing_address.content_attributes) if self.billing_address
      new_invoice.build_shipping_address(self.shipping_address.content_attributes) if self.shipping_address
    
      self.invoice = new_invoice
    
      new_invoice
    end
  
    # Builds billing, shipping and origin addresses
    def build_addresses(options={})
      raise ArgumentError.new("No address declared for buyer (#{buyer.class.name} ##{buyer.id}), use acts_as_addressable") \
        unless buyer.respond_to?(:find_default_address)
    
      # buyer's billing address
      unless self.default_billing_address
        if buyer.respond_to?(:billing_address) && buyer.default_billing_address
          self.build_billing_address(buyer.default_billing_address.content_attributes)
        else
          if buyer_default_address = buyer.find_default_address
            self.build_billing_address(buyer_default_address.content_attributes)
          else
            raise ArgumentError.new(
              "No billing or default address found for buyer (#{buyer.class.name} ##{buyer.id}), use acts_as_addressable")
          end
        end
      end
    
      # buyer's shipping address is optional
      if buyer.respond_to?(:shipping_address)
        self.build_shipping_address(buyer.find_shipping_address_or_clone_from(
          self.billing_address
        ).content_attributes) unless self.default_shipping_address
      end

      # seller's address for origin address
      raise ArgumentError.new("No address declared for seller (#{seller.class.name} ##{seller.id}), use acts_as_addressable") \
        unless seller.respond_to?(:find_default_address)
    
      unless default_origin_address
        if seller.respond_to?(:billing_address) && seller.default_billing_address
          self.build_origin_address(seller.default_billing_address.content_attributes)
        else
          if seller_default_address = seller.find_default_address
            self.build_origin_address(seller_default_address.content_attributes)
          else
            raise ArgumentError.new(
              "No billing or default address found for seller (#{seller.class.name} ##{seller.id}), use acts_as_addressable")
          end
        end
      end
    end
  
  end
end