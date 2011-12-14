require "bundler/setup"
require "rspec"
require "active_record"
require "sqlite3"
require "merchant_sidekick"

# If you want to see the ActiveRecord log, invoke the tests using `rake test LOG=true`
if ENV["LOG"]
  require "logger"
  ActiveRecord::Base.logger = Logger.new($stdout)
end

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
ActiveRecord::Migration.verbose = false

require "merchant_sidekick/migrations/billing"
require "merchant_sidekick/migrations/addressable"
require "merchant_sidekick/migrations/shopping_cart"

CreateMerchantSidekickBillingTables.up
CreateMerchantSidekickAddressableTables.up
CreateMerchantSidekickShoppingCartTables.up

at_exit {ActiveRecord::Base.connection.disconnect!}