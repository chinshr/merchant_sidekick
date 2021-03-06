require "active_record"
require "active_support/core_ext" # TODO remove once we replace inheritable_attribute readers with configurations
require "money"
require "merchant_sidekick/version"
require "merchant_sidekick/money"
require "acts_as_list"
require "aasm"
require "active_merchant"

ActiveRecord::Base.extend MerchantSidekick::Money

require 'merchant_sidekick/addressable/addressable'
require 'merchant_sidekick/addressable/address'
ActiveRecord::Base.send(:include, MerchantSidekick::Addressable)

require 'merchant_sidekick/sellable'
require 'merchant_sidekick/buyer'
require 'merchant_sidekick/seller'

require 'merchant_sidekick/line_item'
require 'merchant_sidekick/order'
require 'merchant_sidekick/purchase_order'
require 'merchant_sidekick/sales_order'
require 'merchant_sidekick/invoice'
require 'merchant_sidekick/purchase_invoice'
require 'merchant_sidekick/sales_invoice'

ActiveRecord::Base.send(:include, MerchantSidekick::Sellable)
ActiveRecord::Base.send(:include, MerchantSidekick::Buyer)
ActiveRecord::Base.send(:include, MerchantSidekick::Seller)

require 'merchant_sidekick/shopping_cart/cart'
require 'merchant_sidekick/shopping_cart/line_item'

require 'merchant_sidekick/gateway'
require 'merchant_sidekick/payment'

require 'merchant_sidekick/active_merchant/credit_card_payment'

require 'merchant_sidekick/active_merchant/gateways/base'
require 'merchant_sidekick/active_merchant/gateways/bogus_gateway'
require 'merchant_sidekick/active_merchant/gateways/authorize_net_gateway'
require 'merchant_sidekick/active_merchant/gateways/paypal_gateway'

require 'merchant_sidekick/railtie' if defined?(Rails)