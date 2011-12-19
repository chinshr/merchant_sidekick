require "merchant_sidekick/migrations/addressable"
require "merchant_sidekick/migrations/billing"
require "merchant_sidekick/migrations/shopping_cart"

CreateMerchantSidekickAddressableTables.up
CreateMerchantSidekickBillingTables.up
CreateMerchantSidekickShoppingCartTables.up

ActiveRecord::Schema.define :version => 0 do
  create_table :addressables, :force => true do |t|
    t.column :name, :string
    t.column :type, :string
  end
end
