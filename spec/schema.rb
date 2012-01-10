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

  create_table :products, :force => true do |t|
    t.column :title, :string
    t.column :description, :text
    t.column :type, :string
    t.column :price_cents, :integer, :null => false, :default => 0
    t.column :price_currency, :string, :null => false, :default => "USD"
  end

  create_table :users, :force => true do |t|
    t.column :name, :string
    t.column :email, :string
    t.column :type, :string
  end
end
