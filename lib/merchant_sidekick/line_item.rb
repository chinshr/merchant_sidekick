# Line Items used in orders and invoices
#
#  LineItem::tax_rate_class_name = 'TaxRate'
#
module MerchantSidekick
  class LineItem < ActiveRecord::Base
    self.table_name = "line_items"
    
    #--- accessors
    cattr_accessor :tax_rate_class_name 
  
    #--- associations
    belongs_to :order, :class_name => "::MerchantSidekick::Order"
    belongs_to :invoice, :class_name => "::MerchantSidekick::Invoice"
    belongs_to :sellable, :polymorphic => true
  
    #--- mixins
    money :net_amount,   :cents => :net_cents,   :currency => "currency"
    money :tax_amount,   :cents => :tax_cents,   :currency => "currency"
    money :gross_amount, :cents => :gross_cents, :currency => "currency"

    #--- callbacks
    before_save :save_sellable

    #--- instance methods
  
    # set #amount when adding sellable.  This method is aliased to <tt>sellable=</tt>.
    def sellable_with_price=(a_sellable)
      calculate(a_sellable)
      self.sellable_without_price = a_sellable
    end
    alias_method_chain :sellable=, :price

    # There used to be a money :amount declration. When we added
    # taxable line items, we assume that amount will refer to the 
    # net_amount (net_cents)
    def amount
      self.net_amount
    end
    alias_method :net_total, :amount

    # Amount amounts to the net, for compatibility reasons
    def amount=(net_money_amount)
      self.net_amount = net_money_amount
    end
    alias_method :net_total=, :amount=

    # shorter for gross_amount
    def total
      self.gross_amount
    end
    alias_method :gross_total, :total
  
    # short for tax_amount
    def tax
      self.tax_amount
    end
    alias_method :tax_total, :tax

    # calculates the amounts, like after an address change in the order and tries to save
    # the line_item unless locked
    # TODO find a better way to determine if the line item can still be updated
    def evaluate
      calculate(self.sellable)
      save(false) unless new_record?
    end

    protected
  
    def calculate(a_sellable)
      if a_sellable && a_sellable.price
        tax_rate_class = tax_rate_class_name.camelize.constantize rescue nil
        
        # calculate tax amounts
        #
        # If we want to provide tax rates based on the order's billing address location,
        # we require a class method, 
        #
        # e.g.
        #
        #   Tax.find_tax_rate({:origin => {...}, :destination => {...}})
        #   # where each hash provides :country_code => 'DE', :state_code => 'BY'
        
        if tax_rate_class && a_sellable.respond_to?(:taxable?) && a_sellable.send(:taxable?)
          # find tax rate for billing address, country/province
          self.tax_rate = tax_rate_class.find_tax_rate(
            :origin => order && order.origin_address ? order.origin_address.content_attributes : {},
            :destination => order && order.shipping_address ? order.shipping_address.content_attributes : {},
            :sellable => a_sellable
          )

          if a_sellable.respond_to?( :price_is_net? ) && a_sellable.send( :price_is_net? )
            # gross = net + tax
            self.net_amount = a_sellable.price
            this_cents, this_currency = self.net_amount.cents, self.net_amount.currency
            this_tax_cents = ( Float( this_cents * self.tax_rate / 10) / 10 ).round
            self.tax_amount = ::Money.new(this_tax_cents, this_currency)
            self.gross_amount = self.net_amount + self.tax_amount
          else # price is gross
            # net = gross - tax
            this_gross_cents, this_currency = a_sellable.price.cents, a_sellable.price.currency
            this_net_cents = (this_gross_cents * Float(100) / Float(100 + self.tax_rate)).round
            self.net_amount = ::Money.new(this_net_cents, this_currency)
            self.gross_amount = a_sellable.price
            self.tax_amount = self.gross_amount - self.net_amount
          end
        else
          # net = gross, tax = 0
          self.net_amount = a_sellable.price
          self.gross_amount = a_sellable.price
          self.tax_amount = ::Money.new(0, a_sellable.currency)
          self.tax_rate = 0
        end
      else
        self.net_cents = 0
        self.gross_cents = 0
        self.tax_cents = 0
        self.tax_rate = 0
        self.currency = "USD"
      end
    end
    
    def save_sellable
      sellable.save if sellable.new_record?
    end
  
  end
end