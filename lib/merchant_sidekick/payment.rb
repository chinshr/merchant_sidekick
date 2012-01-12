# Superclass for all payment transaction. Each purchase, authorization, etc. attempt
# will result in a new sublcass payment instance
module MerchantSidekick
  class Payment < ActiveRecord::Base
    self.table_name = "payments"

    #--- associations
    belongs_to :payable, :polymorphic => true
    acts_as_list :scope => 'payable_id=#{quote_value(payable_id)} AND payable_type=#{quote_value(payable_type)}'

    #--- mixins
    money :amount, :cents => :cents, :currency => :currency

    #--- class methods

    # Determines which payment class to use based on the payment object passed.
    # overriden this if other payment types must be supported, e.g. for bank
    # transfer, etc.
    #
    # E.g.
    #
    #   Payment.class_for(ActiveMerchant::Billing::CreditCard.new(...))
    #   #=>  MerchantSidekick::ActiveMerchant::CreditCardPayment

    def self.class_for(payment_object)
      MerchantSidekick::ActiveMerchant::CreditCardPayment
    end

    def self.content_column_names
      content_columns.map(&:name) - %w(payable_type payable_id kind reference message action params test cents currency lock_version position type uuid created_at updated_at success)
    end

    #--- instance methods

    # override in sublcass
    # infers payment
    def payment_type
      :payment
    end

    # returns true if the payment transaction was successful
    def success?
      !!(self[:success] || false)
    end

    # return only attributes with relevant content
    def content_attributes
      self.attributes.reject {|k,v| !self.content_column_names.include?(k.to_s)}.symbolize_keys
    end

    # returns content column name strings
    def content_column_names
      self.class.content_column_names
    end
  end

  # MerchantSidekick::AuthorizationError
  class AuthorizationError < StandardError; end
end