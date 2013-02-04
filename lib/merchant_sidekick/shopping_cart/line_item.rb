# MerchantSidekick::ShoppingCart::LineItem duplicates the actual purchasable product upon putting a product into a cart.
# This is necessary, because we want to maintain order information even after the product
# might have already been removed from the system.
#
# This class copies many of the product attributes, because product rows usually undergo
# constant changes (description, price, etc.), while the cart_line_item will remain unchanged
# during its lifetime.
module MerchantSidekick
  module ShoppingCart
    class LineItem < ActiveRecord::Base
      self.table_name = "cart_line_items"

      attr_accessor :options

      belongs_to :product, :polymorphic => true
      money :unit_price, :cents => "cents", :currency => "currency"
      acts_as_sellable

      validates_presence_of :product

      def options=(some_options={})
        @options = some_options.to_hash
      end

      def options
        @options || {}
      end

      def product_with_price=(a_product)
        if a_product && (a_product.respond_to?(:price) || a_product.respond_to?(:copy_price))
          self[:taxable] = if a_product.respond_to?(:taxable?)
            a_product.send(:taxable?)
          elsif a_product.respond_to?(:taxable)
            a_product.send(:taxable)
          else
            false
          end

          self[:unit] = a_product.respond_to?(:unit) ? a_product.unit.to_s : 'piece'
          self[:pieces] = a_product.respond_to?(:pieces) ? a_product.pieces : 1

          # name from product copy_name method, name or title column
          self[:name] = if a_product.respond_to?(:copy_name)
            a_product.send(:copy_name, self.options)
          elsif a_product.respond_to?(:title)
            a_product.send(:title)
          elsif a_product.respond_to?(:name)
            a_product.send(:name)
          else
            'No name'
          end

          # item_number from product copy_iten_number method, sku or number column
          self[:item_number] = if a_product.respond_to?(:copy_item_number)
            a_product.send(:copy_item_number, self.options)
          elsif a_product.respond_to?(:sku)
            a_product.send(:sku)
          elsif a_product.respond_to?(:number)
            a_product.send(:number)
          else
            a_product.id unless a_product.new_record?
          end

          # description from product copy_description or description column
          self[:description] = if a_product.respond_to?(:copy_description)
            a_product.send(:copy_description, self.options)
          elsif a_product.respond_to?(:description)
            a_product.send(:description)
          else
            'No description'
          end

          # unit price
          product_unit_price = if a_product.respond_to?(:copy_price)
            a_product.send(:copy_price, self.options)
          else
            a_product.send(:price)
          end
          product_unit_price = ::Money.new(1, self.currency || 'USD') + product_unit_price - ::Money.new(1, self.currency || 'USD')
          self.unit_price = product_unit_price
        end
        self.product_without_price = a_product
      end
      alias_method_chain :product=, :price

      # overwrites from taxable? from acts_as_sellable
      # Important! don't change this to is_taxable?, rather alias it!
      def taxable?
        self.taxable
      end
      alias_method :is_taxable?, :taxable?

      # overwrites from price_is_net? from product
      def price_is_net?
        if self.product
          return self.product.send(:price_is_net?) if self.product.respond_to?(:price_is_net?)
        end
        true
      end

      # overwrites from price_is_gross? from acts_as_sellable
      def price_is_gross?
        !price_is_net?
      end

      # Returns a product name and sets the title attribute
      def name
        self[:name]
      end

      # returns or sets the item number based on the product's
      # SKU, number, or id
      def item_number
        self[:item_number]
      end

      # Make the unit a symbol
      # getter
      def unit
        self[:unit].to_s.empty? ? :piece : self[:unit].to_sym
      end

      # Make the unit a symbol
      # setter
      def unit=(a_unit)
        self[:unit] = a_unit.to_s
      end

      # total price = unit_price * quantity
      # unit_price is defined as money!
      def total_amount
        self.unit_price * (self.quantity || 1)
      end
      alias_method :price, :total_amount
      # alias_method :total_price, :total_amount

      # Price per piece
      # Example:
      #   12 bottles (pieces) of a unit price of $45.00 per box (unit price)
      #   is a per piece price of $3.75
      def price_per_piece
        self.unit_price / (self.pieces || 1) if self.unit_price
      end

      # Returns a localized description text
      # e.g. "12 months subscription for $74 ($5.95 per month)"
      def description
        self[:description]
      end

    end
  end
end