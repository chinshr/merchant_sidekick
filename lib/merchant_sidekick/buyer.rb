module MerchantSidekick
  module Buyer

    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods

      # Defines helper methods for a person buying items.
      #
      # E.g.
      #
      #   class Client < ActiveRecord::Base
      #     acts_as_buyer
      #     ...
      #   end
      #
      #   # Simple purchase
      #   # => @client.purchase @products
      #
      #   # Purchase referencing a seller
      #   # => @client.purchase @products, :from => @merchant
      #
      #   # Same as above
      #   # => @client.purchase_from @merchant, @products
      #
      def acts_as_buyer
        include MerchantSidekick::Buyer::InstanceMethods
        has_many :orders, :as => :buyer, :dependent => :destroy, :class_name => "::MerchantSidekick::Order"
        has_many :invoices, :as => :buyer, :dependent => :destroy, :class_name => "::MerchantSidekick::Invoice"
        has_many :purchase_orders, :as => :buyer, :class_name => "::MerchantSidekick::PurchaseOrder"
        has_many :purchase_invoices, :as => :buyer, :class_name => "::MerchantSidekick::PurchaseInvoice"
      end
    end

    module InstanceMethods

      # like purchase but forces the seller parameter, instead of
      # taking it as a :seller option
      def purchase_from(seller, *arguments)
        purchase(arguments, :from => seller)
      end

      # purchase creates a purchase order based on
      # the given sellables, e.g. product, or basically
      # anything that has a price attribute.
      #
      # E.g.
      #
      #    buyer.purchase(product, :seller => seller)
      #
      def purchase(*arguments)
        sellables = []
        options = default_purchase_options

        # distinguish between options and attributes
        arguments = arguments.flatten
        arguments.each do |argument|
          case argument.class.name
          when 'Hash'
            options.merge! argument
          else
            sellables << (argument.is_a?(MerchantSidekick::ShoppingCart::Cart) ? argument.line_items : argument)
          end
        end
        sellables.flatten!

        raise ArgumentError.new("No sellable (e.g. product) model provided") if sellables.empty?
        raise ArgumentError.new("Sellable models must have a :price") unless sellables.all? {|sellable| sellable.respond_to? :price}

        self.purchase_orders.build do |po|
          po.buyer = self
          po.seller = options[:from]
          po.build_addresses
          sellables.each do |sellable|
            if sellable && sellable.respond_to?(:before_add_to_order)
              sellable.send(:before_add_to_order, self)
              sellable.reload unless sellable.new_record?
            end
            li = LineItem.new(:sellable => sellable, :order => po)
            po.line_items.push(li)
            sellable.send(:after_add_to_order, self) if sellable && sellable.respond_to?(:after_add_to_order)
          end
          self
        end
      end

      protected

      # override in model, e.g. :from => @merchant
      def default_purchase_options
        {}
      end

    end
  end
end