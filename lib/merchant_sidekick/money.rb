module MerchantSidekick
  
  # Extensions to the money gem.
  module Money
    
    # Used to define a composed field that plays well with +merchant_sidekick+. Fore example, use the money
    # class method to define a price attribute for product instances. A money object is composed of +cents+
    # and +currency+ fields in the database.
    #
    # @param [Symbol] name Lets you define the name of the attribute
    # @option options [Symbol] :cents Sets the column name to use as cents amount, default "cents".
    # @option options [Symbol] :currency Sets the column name to use as currency, default "currency".
    #
    # @example
    #   class Product < ActiveRecord::Base
    #     money :price, :cents => "price_cents", :currency => "price_currency"
    #   end
    #
    #   @product = Product.new :price_cents => 1050, :price_currency => "USD"
    #   @product.price.format # => "$10.50"
    def money(name, options = {})
      options = {:cents => "#{name}_cents".to_sym}.merge(options)
      mapping = [[options[:cents].to_s, 'cents']]
      mapping << ([options[:currency].to_s, 'currency_as_string']) if options[:currency]

      composed_of name,
        :class_name => "::Money",
        :mapping => mapping,
        :constructor => Proc.new {|cents, currency| ::Money.new(cents || 0, currency || ::Money.default_currency)},
        :converter => Proc.new {|value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money")}

      if options[:currency]
        class_eval(<<-END, __FILE__, __LINE__+1)
          def currency
            ::Money::Currency.wrap(self[:#{options[:currency]}])
          end

          def currency_as_string
            self[:#{options[:currency]}]
          end
        END
      else
        class_eval(<<-END, __FILE__, __LINE__+1)
          def currency
            ::Money.default_currency
          end

          def currency_as_string
            ::Money.default_currency.to_s
          end
        END
      end

    end
  end
end