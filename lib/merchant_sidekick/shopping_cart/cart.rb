# The Cart model is a non-persistant shopping cart. It provides methods
# to add, remove "purchasables". It follows the model where purchasables are
# not the actual products, but rather the product lines.
module MerchantSidekick
  module ShoppingCart
    class Cart
      attr_reader :line_items
      attr_reader :currency
      attr_accessor :options
  
      def initialize(currency_code = 'USD', options = {})
        @currency = currency_code
        @options = {:currency_code => currency_code}.merge(options)
        empty!
      end

      # Add a cart_line_item or a product. In case, a product is added
      # it will be copied and the copy added as a cart_line_item.
      # if thing is a Product, it needs to be converted to a 
      # MerchantSidekick::ShoppingCart::LineItem first.
      def add(thing, quantity=1, options={})
        if thing.is_a?(MerchantSidekick::ShoppingCart::LineItem)
          self.add_cart_line_item(thing, options)
        else
          # Product
          self.add_product(thing, quantity, options)
        end
      end

      # Removes an item from the cart
      def remove(thing, options={})
        if thing.is_a?(MerchantSidekick::ShoppingCart::LineItem)
          self.remove_cart_line_item(thing, options)
        else
          self.remove_product(thing, options)
        end
      end
      alias_method :delete, :remove

      # updates an existing line_item with quantity by product or line_item
      # instance. If quanity is <= 0, the item will be removed.
      def update(thing, quantity, options={})
        if thing.is_a?(MerchantSidekick::ShoppingCart::LineItem)
          self.update_cart_line_item(thing, quantity, options)
        else
          self.update_product(thing, quantity, options)
        end
      end

      # Finds an instance of line item, by product or line_item
      # e.g.
      # find(:first, @product)
      def find(what, thing, options={})
        if thing.is_a?(MerchantSidekick::ShoppingCart::LineItem)
          self.find_line_items(what, thing, options)
        else
          self.find_line_items_by_product(what, thing, options)
        end
      end

      # Empty cart
      def empty!
        @line_items = []
      end

      def empty?
        @line_items.empty?
      end
  
      def total_price
        sum = ::Money.new(1, self.currency)
        @line_items.each {|i| sum += i.total_price }
        sum -= ::Money.new(1, self.currency)
        sum
      end
      alias_method :total, :total_price
      alias_method :sub_total, :total_price

      # counts number of line items
      def line_items_count
        self.line_items.size
      end

      # counts number of entities line_items * quantities
      def items_count
        counter = 0
        self.line_items.each do |item|
          counter += item.quantity
        end
        counter
      end

      # Create a product line from a product (product) and copy
      # all attributes that could be modified later
      def cart_line_item(product, quantity=1, line_options={})
        raise "No price column available for '#{product.class.name}'" unless product.respond_to?(:price)
        # we need to set currency explicitly here for correct money conversion of the cart_line_item
        MerchantSidekick::ShoppingCart::LineItem.new do |line_item| 
          line_item.options = self.options.merge(line_options)
          line_item.currency = self.currency
          line_item.quantity = quantity
          line_item.product = product
          line_item
        end
      end

      # Return a list of cart line items from an array of products, e.g. Products
      def cart_line_items(products)
        products.collect { |p| self.cart_line_item(p) }
      end

      # cart options setter
      def options=(some_options={})
        @options = some_options.to_hash
      end

      # cart options getter
      def options
        @options || {}
      end

      protected

      # Add product line
      # Returns cart total price
      def add_cart_line_item(newitem, options={})
        return nil if newitem.nil?
        item = find(:first, newitem)
        if item
          # existing item found, update item quantity and add total_price
          item.quantity += newitem.quantity
        else
          # not in cart yet
          item = newitem
          @line_items << item
        end
        item
      end
  
      # Add purchasable, which most likely will be a product
      # Returns the total price
      def add_product(a_product, quantity=1, options={})
        return nil if a_product.nil?
        item = find(:first, a_product)
        if item
          item.quantity += quantity
        else
          item = self.cart_line_item(a_product, quantity, options)
          @line_items << item
        end
        item
      end

      # Remove a product line and adjust the total price
      def remove_cart_line_item(a_cart_line_item, options={})
        deleted_line_item = nil
        item_to_remove = find(:first, a_cart_line_item)
        deleted_line_item = @line_items.delete(item_to_remove) if item_to_remove
        deleted_line_item
      end
  
      # Remove a purchasable and adjust the total price
      def remove_product(a_product, options={})
        deleted_line_item = nil
        item_to_remove = find(:first, a_product)
        deleted_line_item = @line_items.delete(item_to_remove) if item_to_remove
        deleted_line_item
      end

      # updates quantity by line item
      def update_cart_line_item(a_line_item, quantity, options={})
        return remove(a_line_item, options) if quantity <= 0
        item = find(:first, a_line_item)
        item.quantity = quantity if item
        item
      end
  
      # updates quantity py product
      def update_product(a_product, quantity, options={})
        return remove(a_product, options) if quantity <= 0
        item = find(:first, a_product)
        item.quantity = quantity if item
        item
      end

      def find_line_items(what, a_cart_line_item, options={})
        if :all == what
          @line_items.select { |i| i.product_id == a_cart_line_item.product.id && i.product_type == a_cart_line_item.product.class.base_class.name }
        elsif :first == what
          @line_items.find { |i| i.product_id == a_cart_line_item.product.id && i.product_type == a_cart_line_item.product.class.base_class.name }
        end
      end
  
      def find_line_items_by_product(what, a_product, options={})
        if :all == what
          @line_items.select { |i| i.product_id == a_product.id && i.product_type == a_product.class.base_class.name }
        elsif :first == what
          @line_items.find { |i| i.product_id == a_product.id && i.product_type == a_product.class.base_class.name }
        end
      end
    end
  end
end
