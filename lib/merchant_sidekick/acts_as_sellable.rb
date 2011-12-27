module MerchantSidekick
  module Sellable
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      
      # Declares a model as sellable
      #
      # A sellable model must have a field that stores the price in cents.
      #
      # === Options:
      # * <tt>:cents</tt>: name of cents field (default :cents).
      # * <tt>:currency</tt>: name of currency field (default :currency). Set to <tt>false</tt>
      #   diable storing the currency, causing it to default to USD
      #
      # === Example:
      #
      #   class Product < ActiveRecord::Base
      #     acts_as_sellable :cents => :price_in_cents, :currency => false
      #   end
      #
      def acts_as_sellable(options = {})
        include MerchantSidekick::Sellable::InstanceMethods
        extend MerchantSidekick::Sellable::SingletonMethods
        money :price, options
        has_many :line_items, :as => :sellable, :class_name => "MerchantSidekick::LineItem"
        has_many :orders, :through => :line_items, :class_name => "MerchantSidekick::Order"
      end
    end
    
    module SingletonMethods
      def sellable?
        true
      end
    end
    
    module InstanceMethods
      
      def sellable?
        true
      end
      
      # Funny name, but it returns true if the :price represents
      # a gross price including taxes. For that there must be a 
      # method called price_is_gross or price_is_gross! as it is
      # in Issue model
      # price_is_net? and/or price_is_gross? should be overwritten
      def price_is_gross?
        false
      end
      
      # Opposite of price_is_gross?
      def price_is_net?
        true
      end
      
      # This is a product, where the gross and net prices are equal, or in other words
      # a tax for this product is not applicable, e.g. for $10 purchasing credit
      # should be overwritten if otherwise
      def taxable?
        true
      end
      
      # There can only be one authorized order per sellable,
      # so the first authorziation is it!
      #
      # Usage:
      #   order = issue.settle
      #   order.capture unless order.nil?
      # Options:
      #   issue.settle :merchant => person
      #
      def settle(options={})
        self.orders.each do |order|
          if order.kind == 'authorization' && current_line_item = order.line_items_find(
            :first, :condition => ["sellable_id => ? AND sellable_type = ?", self.id, self.class.name]
          )
            if adjusted_line_item=order.line_items.build( :order => order, :sellable => self )
              current_line_items.destroy
              order.build_addresses
              order.update
              order.save!
              return order
            end
          end
        end
        nil
      end
    end
  end
end