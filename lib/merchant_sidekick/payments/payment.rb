# Superclass for all payment transaction. Each purchase, authorization, etc. attempt
# will result in a new sublcass payment instance
module MerchantSidekick
  module Payments
    class Payment < ActiveRecord::Base
      self.table_name = "payments"

      #--- associations
      belongs_to :payable, :polymorphic => true
      acts_as_list :scope => 'payable_id=#{quote_value(payable_id)} AND payable_type=#{quote_value(payable_type)}'

      #--- mixins
      money :amount, :cents => :cents, :currency => :currency

      #--- class methods
  
      # determines which payment class to use based on the payment object passed.
      # overriden this if other payment types must be supported, like bank
      # transfer, etc.
      # 
      # e.g. Payment.class_for(ActiveMerchant::Billing::CreditCard.new(...))
      #   returns CreditCardPayment class
      def self.class_for(payment_object)
        CreditCardPayment
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
  
      # Used to display payment type in views
      # e.g. 'Credit Card'
      def payment_type_display
        payment_type.to_s.titleize
      end
      alias_method :payment_method_display, :payment_type_display

      # returns true if the payment transaction was successful
      def success?
        self[:success] || false
      end

      # return only attributes with relevant content
      def content_attributes
        self.attributes.reject {|k,v| !self.content_column_names.include?(k.to_s)}.symbolize_keys
      end
  
      # returns content column name strings 
      def content_column_names
        self.class.content_column_names
      end

      #--- exceptions
      class AuthorizationError < StandardError; end
  
    end
  end
end