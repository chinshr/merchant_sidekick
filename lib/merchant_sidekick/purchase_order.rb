# Implements outbound orders, i.e. the merchant sells a product to a user
module MerchantSidekick
  class PurchaseOrder < Order
    has_many :purchase_invoices, :foreign_key => :order_id, :class_name => "MerchantSidekick::PurchaseInvoice"

    # Authorizes a payment over the order gross amount
    def authorize(payment_object, options={})
      defaults = {:order_id => number}
      options = defaults.merge(options).symbolize_keys
      transaction do
        buyer.send(:before_authorize_payment, self) if buyer && buyer.respond_to?(:before_authorize_payment)
        self.build_addresses
        self.build_invoice unless self.last_unsaved_invoice
        authorization_result = self.last_unsaved_invoice.authorize(payment_object, options)
        if authorization_result.success?
          process_payment!
        end
        buyer.send(:after_authorize_payment, self) if buyer && buyer.respond_to?(:after_authorize_payment)
        authorization_result
      end
    end

    # Captures the amount of the order that was previously authorized
    # If the capture amount
    def capture(options={})
      defaults = {:order_id => number}
      options = defaults.merge(options).symbolize_keys

      if invoice = self.purchase_invoices.find(:all, :created_at => "invoices.id ASC").last
        buyer.send(:before_capture_payment, self) if buyer && buyer.respond_to?(:before_capture_payment)
        capture_result = invoice.capture(options)
        if capture_result.success?
          approve_payment!
        end
        buyer.send(:after_capture_payment, self) if buyer && buyer.respond_to?(:after_capture_payment)
        capture_result
      end
    end

    # Pay the order and generate invoice
    def pay(payment_object, options={})
      defaults = { :order_id => number }
      options = defaults.merge(options).symbolize_keys

      # before_payment
      buyer.send( :before_payment, self ) if buyer && buyer.respond_to?( :before_payment )

      self.build_addresses
      self.build_invoice unless self.last_unsaved_invoice

      payment = self.last_unsaved_invoice.purchase(payment_object, options)
      if payment.success?
        process_payment!
        approve_payment!
      end
      save!
      # after_payment
      buyer.send( :after_payment, self ) if buyer && buyer.respond_to?( :after_payment )
      payment
    end

    # Voids a previously authorized invoice payment and sets the status to cancel
    # Usage:
    #   void(options = {})
    #
    def void(options={})
      defaults = { :order_id => self[:number] }
      options = defaults.merge(options).symbolize_keys

      if invoice = self.purchase_invoices.find(:all, :created_at => "invoices.id ASC").last
        # before_payment
        buyer.send( :before_void_payment, self ) if buyer && buyer.respond_to?( :before_void_payment )

        voided_result = invoice.void(options)

        if voided_result.success?
          cancel!
        end
        save!
        # after_void_payment
        buyer.send(:after_void_payment, self) if buyer && buyer.respond_to?(:after_void_payment)
        voided_result
      end
    end

    # refunds a previously paid order
    # Note: :card_number must be supplied
    def refund(options={})
      defaults = { :order_id => number }
      options = defaults.merge(options).symbolize_keys

      if (invoice = self.purchase_invoices.find(:all, :created_at => "invoices.id ASC").last) && invoice.paid?
        # before_payment
        buyer.send(:before_refund_payment, self) if buyer && buyer.respond_to?(:before_refund_payment)

        refunded_result = invoice.credit(options)
        if refunded_result.success?
          refund!
        end
        save!
        # after_void_payment
        buyer.send( :after_refund_payment, self ) if buyer && buyer.respond_to?( :after_refund_payment )
        refunded_result
      end
    end

    # E.g.
    #
    #   @order.recurring(@payment, :interval => {:length => 1, :unit => :month},
    #    :duration => {:start_date => Date.today, :occurrences => 999})
    #
    def recurring(payment_object, options={})
      defaults = {:order_id => number}
      options = defaults.merge(options).symbolize_keys

      self.build_addresses

      authorization = Payment.class_for(payment_object).recurring(
        gross_total, payment_object, payment_options(options))

      self.push_payment(authorization)

      if authorization.success?
        save(false)
        process_payment!
      else
        # we don't want to save the payment and related objects
        # when the authorization fails
        # transaction_declined!
      end
      authorization
    end

    # E.g.
    #
    #   @order.pay_recurring("c3s34", :add_line_items => @line_items)
    #
    def pay_recurring(authorization=nil, options={})
      # recurring payment
      recurring_payment = if authorization.nil?
        self.payments.recurring.find(:all, :order => "payments.id ASC").last
      elsif authorization.is_a?(Payment) && self.payments.include?(authorization)
        authorization
      else
        self.payments.find(:first, :conditions => ["payments.id = ? OR payments.reference = ? OR payments.uuid = ?", authorization])
      end

      # recurring expired
      if !self.pending? || self.purchase_invoices.paid.count > recurring_payment.duration_occurrences
        raise MerchantSidekick::RecurringPaymentError, "Recurring order #{self.number} expired"
      end

      transaction do
        buyer.send(:before_pay_recurring, self) if buyer && buyer.respond_to?(:before_pay_recurring)
        self.additional_line_items(options[:add_line_items])
        self.build_invoice unless self.last_unsaved_invoice

        authorization_result = self.last_unsaved_invoice.purchase(recurring_payment, options)
        if authorization_result.success?
          # add next billing due date
          process_payment!
        end
        buyer.send(:after_pay_recurring, self) if buyer && buyer.respond_to?(:before_pay_recurring)
        authorization_result
      end
    end

    def authorize_recurring(authorization=nil, options={})
      # recurring payment
      recurring_payment = if authorization.nil?
        self.payments.recurring.find(:all, :order => "payments.id ASC").last
      elsif authorization.is_a?(Payment) && self.payments.include?(authorization)
        authorization
      else
        self.payments.find(:first, :conditions => ["payments.id = ? OR payments.reference = ? OR payments.uuid = ?", authorization])
      end

      # recurring expired
      if !self.pending? || self.purchase_invoices.paid.count > recurring_payment.duration_occurrences
        raise MerchantSidekick::RecurringPaymentError, "Recurring order #{self.number} expired"
      end

      transaction do
        buyer.send(:before_authorize_recurring, self) if buyer && buyer.respond_to?(:before_authorize_recurring)
        self.additional_line_items(options[:add_line_items])
        self.build_invoice unless self.last_unsaved_invoice

        authorization_result = self.last_unsaved_invoice.authorize(recurring_payment, options)
        if authorization_result.success?
          process_payment!
        end
        buyer.send(:after_authorize_recurring, self) if buyer && buyer.respond_to?(:after_authorize_recurring)
        authorization_result
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
        :order_number => self.number,
        #:invoice => self.number,
        :merchant => self.seller ? "#{self.seller.name} (#{self.seller.id})" : nil,
        :currency => self.currency,
        :billing_address => self.billing_address ? self.billing_address.to_merchant_attributes : nil,
        :shipping_address =>  self.shipping_address ? self.shipping_address.to_merchant_attributes : nil
      }.merge(options)
    end

    # yes, i am a purchase order!
    def purchase_order?
      true
    end

    # used in build_invoice to determine which type of invoice
    def to_invoice_class_name
      'PurchaseInvoice'
    end

    # returns last unsaved invoice
    def last_unsaved_invoice
      unless self.purchase_invoices.empty?
        self.purchase_invoices.last.new_record? ? self.purchase_invoices.last : nil
      else
        nil
      end
    end

    def build_invoice
      new_invoice = self.purchase_invoices.build(
        :line_items       => self.duplicate_line_items,
        :net_amount       => self.net_total,
        :tax_amount       => self.tax_total,
        :gross_amount     => self.gross_total,
        :buyer            => self.buyer,
        :seller           => self.seller,
        :origin_address   => self.origin_address ? self.origin_address.dup : nil,
        :billing_address  => self.billing_address ? self.billing_address.dup : nil,
        :shipping_address => self.shipping_address ? self.shipping_address.dup : nil
      )

      # set new invoice's line items to invoice we just created
      new_invoice.line_items.each do |li|
        if li.new_record?
          li.invoice = new_invoice
        else
          li.update_attribute(:invoice, new_invoice)
        end
      end

      # duplicate addresses
      new_invoice.build_origin_address(self.origin_address.content_attributes) if self.origin_address
      new_invoice.build_billing_address(self.billing_address.content_attributes) if self.billing_address
      new_invoice.build_shipping_address(self.shipping_address.content_attributes) if self.shipping_address

      new_invoice.evaluate
      @additional_line_items = nil
      new_invoice
    end

    # make sure we get a copy of the line items
    def duplicate_line_items
      result = []
      lis = self.line_items
      lis += @additional_line_items.to_a
      lis.each do |line_item|
        li = line_item.dup # Note: use clone in Rails < 3.1
        li.sellable = line_item.sellable
        li.net_amount = line_item.net_amount
        li.gross_amount = line_item.gross_amount
        li.order = nil
        result << li
      end
      result
    end

    # process additional line items before build invoice
    def additional_line_items(items)
      # add line items
      if !items.blank?
        if items.is_a?(Array) && items.all? {|i| i.is_a?(MerchantSidekick::ShoppingCart::LineItem)}
          duped = self.buyer.dup
          order = duped.purchase items
          @additional_line_items = order.line_items
        elsif items.is_a?(Array) && items.all? {|i| i.is_a?(LineItem)}
          @additional_line_items = items
        elsif items.is_a?(Array) && items.all? {|i| i.is_a?(Product)}
          # array of products
          duped = self.buyer.dup
          cart = Cart.new(self.currency)
          items.each {|product| cart.add(product)}
          order = duped.purchase cart.line_items
          @additional_line_items = order.line_items
        end
      end
    end

    # Builds billing, shipping and origin addresses
    def build_addresses(options={})
      raise ArgumentError.new("No address declared for buyer (#{buyer.class.name} ##{buyer.id}), use e.g. class #{buyer.class.name}; has_address; end") \
        unless buyer.respond_to?(:find_default_address)

      # buyer's billing or default address
      unless default_billing_address
        if buyer.respond_to?(:billing_address) && buyer.default_billing_address
          self.build_billing_address(buyer.default_billing_address.content_attributes)
        else
          if buyer_default_address = buyer.find_default_address
            self.build_billing_address(buyer_default_address.content_attributes)
          else
            raise ArgumentError.new(
              "No billing or default address for buyer (#{buyer.class.name} ##{buyer.id}), use e.g. class #{buyer.class.name}; has_address :billing; end")
          end
        end
      end

      # buyer's shipping address
      if buyer.respond_to?(:shipping_address)
        self.build_shipping_address(buyer.find_shipping_address_or_clone_from(
          self.billing_address
        ).content_attributes) unless self.default_shipping_address
      end

      self.billing_address.street = "#{Merchant::Sidekick::Version::NAME}" if self.billing_address && self.billing_address.street.to_s =~ /^backend$/
      self.shipping_address.street = "#{Merchant::Sidekick::Version::NAME}" if self.shipping_address && self.shipping_address.street.to_s =~ /^backend$/

      # seller's billing or default address
      if seller
        raise ArgumentError.new("No address for seller (#{seller.class.name} ##{seller.id}), use acts_as_addressable") \
          unless seller.respond_to?(:find_default_address)

        unless default_origin_address
          if seller.respond_to?(:billing_address) && seller.find_billing_address
            self.build_origin_address(seller.find_billing_address.content_attributes)
          else
            if seller_default_address = seller.find_default_address
              self.build_origin_address(seller_default_address.content_attributes)
            end
          end
        end
      end
    end

  end

  class ::MerchantSidekick::RecurringPaymentError < Exception
  end
end