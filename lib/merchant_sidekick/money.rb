module MerchantSidekick
  module Money
    def money(name, options = {})
      options = {:cents => "#{name}_in_cents".to_sym, :currency => ::Money.default_currency.iso_code}.merge(options)
      mapping = [[options[:cents].to_s, 'cents']]
      mapping << [options[:currency].to_s, 'currency'] if options[:currency]
      
      composed_of name, :class_name => "Money", :mapping => mapping,
        :constructor => Proc.new {|cents, currency| Money.new(cents || 0, currency || ::Money.default_currency.iso_code)},
        :converter => Proc.new {|value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money")}
    end
  end
end