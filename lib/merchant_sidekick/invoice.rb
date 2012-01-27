# Baseclass for in- and outbound invoices.
module MerchantSidekick
  class Invoice < ActiveRecord::Base
    include AASM
    # include ActionView::Helpers::TextHelper
    self.table_name = "invoices"

    attr_accessor :authorization

    belongs_to :seller, :polymorphic => true
    belongs_to :buyer, :polymorphic => true
    has_many   :line_items, :class_name => "MerchantSidekick::LineItem"
    belongs_to :order, :class_name => "MerchantSidekick::Order"
    has_many   :payments, :as => :payable, :dependent => :destroy, :class_name => "MerchantSidekick::Payment"

    money :net_amount,   :cents => :net_cents,   :currency => :currency
    money :tax_amount,   :cents => :tax_cents,   :currency => :currency
    money :gross_amount, :cents => :gross_cents, :currency => :currency
    has_address :origin, :billing, :shipping

    #--- state machine
    aasm :column => "status" do
      state :pending,          :enter => :enter_pending,          :exit => :exit_pending, :initial => true
      state :authorized,       :enter => :enter_authorized,       :exit => :exit_authorized
      state :paid,             :enter => :enter_paid,             :exit => :exit_paid
      state :voided,           :enter => :enter_voided,           :exit => :exit_voided
      state :refunded,         :enter => :enter_refunded,         :exit => :exit_refunded
      state :payment_declined, :enter => :enter_payment_declined, :exit => :exit_payment_declined

      event :payment_paid do
        transitions :from => :pending, :to => :paid, :guard => :guard_payment_paid_from_pending
      end

      event :payment_authorized do
        transitions :from => :pending, :to => :authorized, :guard => :guard_payment_authorized_from_pending
        transitions :from => :payment_declined, :to => :authorized, :guard => :guard_payment_authorized_from_payment_declined
      end

      event :payment_captured do
        transitions :from => :authorized, :to => :paid, :guard => :guard_payment_captured_from_authorized
      end

      event :payment_voided do
        transitions :from => :authorized, :to => :voided, :guard => :guard_payment_voided_from_authorized
      end

      event :payment_refunded do
        transitions :from => :paid, :to => :refunded, :guard => :guard_payment_refunded_from_paid
      end

      event :transaction_declined do
        transitions :from => :pending, :to => :payment_declined, :guard => :guard_transaction_declined_from_pending
        transitions :from => :payment_declined, :to => :payment_declined, :guard => :guard_transaction_declined_from_payment_declined
        transitions :from => :authorized, :to => :authorized, :guard => :guard_transaction_declined_from_authorized
      end
    end

    # state transition callbacks
    def enter_pending; end
    def enter_authorized; end
    def enter_paid; end
    def enter_voided; end
    def enter_refunded; end
    def enter_payment_declined; end

    def exit_pending; end
    def exit_authorized; end
    def exit_paid; end
    def exit_voided; end
    def exit_refunded; end
    def exit_payment_declined; end

    # event guard callbacks
    def guard_transaction_declined_from_authorized; true; end
    def guard_transaction_declined_from_payment_declined; true; end
    def guard_transaction_declined_from_pending; true; end
    def guard_payment_refunded_from_paid; true; end
    def guard_payment_voided_from_authorized; true; end
    def guard_payment_captured_from_authorized; true; end
    def guard_payment_authorized_from_payment_declined; true; end
    def guard_payment_authorized_from_pending; true; end
    def guard_payment_paid_from_pending; true; end

    #--- scopes
    scope :paid, where(:status => "paid")

    #--- callbacks
    before_save :number

    #--- instance methods
    alias_method :current_state, :aasm_current_state

    def number
      self[:number] ||= Order.generate_unique_id
    end

    # returns a hash of additional merchant data passed to authorize
    # you want to pass in the following additional options
    #
    #   :ip => ip address of the buyer
    #
    def payment_options(options={})
      {}.merge(options)
    end

    # From payments, returns :credit_card, etc.
    def payment_type
      payments.first.payment_type if payments
    end
    alias_method :payment_method, :payment_type

    # Human readable payment type
    def payment_type_display
      self.payment_type.to_s.titleize
    end
    alias_method :payment_method_display, :payment_type_display

    # Net total amount
    def net_total
      self.net_amount ||= line_items.inject(::Money.new(0, self.currency || ::Money.default_currency.iso_code)) {|sum,line| sum + line.net_amount}
    end

    # Calculates tax and sets the tax_amount attribute
    # It adds tax_amount across all line_items
    def tax_total
      self.tax_amount = line_items.inject(::Money.new(0, self.currency || ::Money.default_currency.iso_code)) {|sum,line| sum + line.tax_amount}
      self.tax_amount
    end

    # Gross amount including tax
    def gross_total
      self.gross_amount ||= self.net_total + self.tax_total
    end

    # Same as gross_total
    def total
      self.gross_total
    end

    # updates the order and all contained line_items after an address has changed
    # or an order item was added or removed. The order can only be evaluated if the
    # created state is active. The order is saved if it is an existing order.
    # Returns true if evaluation happend, false if not.
    def evaluate
      result = false
      self.line_items.each(&:evaluate)
      self.calculate
      result = save(false) unless self.new_record?
      result
    end

    protected

    # override in subclass
    def purchase_invoice?
      false
    end

    # marks sales invoice, override in subclass
    def sales_invoice?
      false
    end

    def push_payment(a_payment)
      a_payment.payable = self
      self.payments.push(a_payment)
    end

    # Recalculates the order, adding order lines, tax and gross totals
    def calculate
=begin
      self.net_amount = nil
      self.tax_amount = nil
      self.gross_amount = nil
=end
      self.total
    end
  end
end
