require "active_record"
require "money"
require 'merchant_sidekick/version'
require 'merchant_sidekick/money'
require 'acts_as_list'

ActiveRecord::Base.extend MerchantSidekick::Money

require 'merchant_sidekick/addressable/addressable'
require 'merchant_sidekick/addressable/address'
ActiveRecord::Base.send(:include, MerchantSidekick::Addressable)

# require 'merchant_sidekick/acts_as_sellable'
# require 'merchant_sidekick/acts_as_buyer'
# require 'merchant_sidekick/acts_as_seller'
#
# require 'merchant_sidekick/line_item'
# require 'merchant_sidekick/order'
# require 'merchant_sidekick/purchase_order'
# require 'merchant_sidekick/sales_order'
# require 'merchant_sidekick/invoice'
# require 'merchant_sidekick/purchase_invoice'
# require 'merchant_sidekick/sales_invoice'
#
# require 'merchant_sidekick/shopping_cart/cart'
# require 'merchant_sidekick/shopping_cart/line_item'
#
# require 'merchant_sidekick/gateways/gateway'
# require 'merchant_sidekick/gateways/authorize_net_gateway'
# require 'merchant_sidekick/gateways/paypal_gateway'
#
require 'merchant_sidekick/payments/payment'
# require 'merchant_sidekick/payments/credit_card_payment'
#
# ActiveRecord::Base.send(:include, MerchantSidekick::Buyer)
# ActiveRecord::Base.send(:include, MerchantSidekick::Sellable)
# ActiveRecord::Base.send(:include, MerchantSidekick::Seller)