require "bundler/setup"
require "rspec"
require "active_record"
require "sqlite3"
require "merchant_sidekick"

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

require "merchant_sidekick/migrations/billing"
require "merchant_sidekick/migrations/addressable"
require "merchant_sidekick/migrations/shopping_cart"


CreateMerchantSidekickBillingTables.up
CreateMerchantSidekickAddressableTables.up
CreateMerchantSidekickShoppingCartTables.up

at_exit {ActiveRecord::Base.connection.disconnect!}