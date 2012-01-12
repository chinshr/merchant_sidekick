# The Cart class implements a non-persistant shopping cart. 
# It provides methods to add, remove and update "sellable" items. Each sellable
# item added to the cart is converted to a cart line item. It is recommended 
# to make use of the shopping cart's indirection of purchasing cart line items 
# as products often change there properties, i.e. price, description, etc., as
# shown in the following example:
#
#   Purchase w/ cart (recommended)      |  Simple purchase wo/ cart
#   ------------------------------------+------------------------------------
#   @cart = Cart.new                    |  @order = @buyer.purchase @products
#   @cart.add @products                 |
#   @order = @buyer.purchase @cart      |
#
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

      # Adds a single or array of sellable products to the cart and 
      # returns the cart line items.
      #
      # E.g.
      # 
      #   @cart.add @sellable
      #   @cart.add @sellable, 4
      #   @cart.add [@sellable1, @sellable2]
      #
      def add(stuff, quantity = 1, options = {})
        if stuff.is_a?(Array)
          stuff.inject([]) {|result, element| result << add(element, quantity, options)}
        elsif stuff.is_a?(MerchantSidekick::ShoppingCart::LineItem)
          self.add_cart_line_item(stuff, options)
        else
          # assuming it is a "product" (e.g. sellable) instance
          self.add_product(stuff, quantity, options)
        end
      end

      # Removes an item from the cart
      def remove(stuff, options={})
        if stuff.is_a?(MerchantSidekick::ShoppingCart::LineItem)
          self.remove_cart_line_item(stuff, options)
        else
          self.remove_product(stuff, options)
        end
      end
      alias_method :delete, :remove

      # Updates an existing line_item with quantity by product or line_item
      # instance. If quanity is <= 0, the item will be removed.
      def update(stuff, quantity, options={})
        if stuff.is_a?(MerchantSidekick::ShoppingCart::LineItem)
          self.update_cart_line_item(stuff, quantity, options)
        else
          self.update_product(stuff, quantity, options)
        end
      end

      # Finds an instance of line item, by product or line_item
      #
      # E.g.
      #
      #   @cart.find(:first, @product) # -> @li
      #   @cart.find(:all, @product)   # -> [@li1, @li2]
      #
      def find(what, stuff, options={})
        if stuff.is_a?(MerchantSidekick::ShoppingCart::LineItem)
          self.find_line_items(what, stuff, options)
        else
          self.find_line_items_by_product(what, stuff, options)
        end
      end

      # Remove all line items from cart
      def empty!
        @line_items = []
      end

      # Check to see if cart is empty?
      def empty?
        @line_items.empty?
      end

      # Evaluates the total amount of a sum as all item prices * quantity
      def total_amount
        sum = ::Money.new(1, self.currency)
        @line_items.each {|li| sum += li.total_amount}
        sum -= ::Money.new(1, self.currency)
        sum
      end
      alias_method :total, :total_amount

      # counts number of line items.
      def line_items_count
        self.line_items.size
      end

      # counts number of entities line_items * quantities.
      def items_count
        counter = 0
        self.line_items.each do |item|
          counter += item.quantity
        end
        counter
      end

      # Create a product line from a product (sellable) and copies
      # all attributes that could be modified later
      def cart_line_item(product, quantity = 1, line_options = {})
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
        products.map {|p| self.cart_line_item(p)}
      end

      # cart options setter
      def options=(some_options = {})
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
