class CreateMerchantSidekickBillingTables < ActiveRecord::Migration

  def self.up
    create_table :line_items do |t|
      t.integer "order_id"
      t.integer "invoice_id"
      t.integer "sellable_id"
      t.string  "sellable_type"
      t.integer "net_cents",     :default   => 0, :null => false
      t.integer "tax_cents",     :default   => 0, :null => false
      t.integer "gross_cents",   :default   => 0, :null => false
      t.string  "currency",      :default   => "USD", :null => false
#      t.decimal "tax_rate",      :precision => 15, :scale => 10, :default => 0.0, :null => false 
      t.float "tax_rate",      :default => 0.0, :null => false 
      t.timestamps
    end
    add_index :line_items, "order_id"
    add_index :line_items, "invoice_id"
    add_index :line_items, ["sellable_id", "sellable_type"]


    create_table :orders do |t|
      t.integer  "buyer_id"
      t.string   "buyer_type"
      t.integer  "seller_id"
      t.string   "seller_type"
      t.integer  "invoice_id"
      t.integer  "net_cents",                                 :default => 0,         :null => false
      t.integer  "tax_cents",                                 :default => 0,         :null => false
      t.integer  "gross_cents",                               :default => 0,         :null => false
      t.string   "currency",                     :limit => 3, :default => "USD",     :null => false
      t.string   "type"
      t.string   "status",                                    :default => "created", :null => false
      t.string   "number"
      t.string   "description"
      t.datetime "canceled_at"
      t.timestamps
    end
    add_index :orders, ["buyer_id", "buyer_type"]
    add_index :orders, ["seller_id", "seller_type"]
    add_index :orders, "status"
    add_index :orders, "type"


    create_table :invoices do |t|
      t.integer  "buyer_id"
      t.string   "buyer_type"
      t.integer  "seller_id"
      t.string   "seller_type"
      t.integer  "net_cents",               :default => 0,         :null => false
      t.integer  "tax_cents",               :default => 0,         :null => false
      t.integer  "gross_cents",             :default => 0,         :null => false
      t.string   "currency",                :default => "USD",     :null => false
      t.string   "type"
      t.string   "number"
      t.string   "status",                  :default => "pending", :null => false
      t.datetime "paid_at"
      t.integer  "order_id"
      t.datetime "authorized_at"
      t.timestamps
    end
    add_index :invoices, ["buyer_id", "buyer_type"]
    add_index :invoices, "number"
    add_index :invoices, "order_id"
    add_index :invoices, ["seller_id", "seller_type"]
    add_index :invoices, "type"


    #--- payments
    create_table :payments do |t|
      t.integer  "payable_id"
      t.string   "payable_type"
      t.boolean  "success"
      t.string   "reference"
      t.string   "message"
      t.string   "action"
      t.string   "params"
      t.boolean  "test"
      t.integer  "cents",                                :default => 0,     :null => false
      t.string   "currency",                :limit => 3, :default => "USD", :null => false
      t.integer  "position"
      t.string   "type"
      t.string   "paypal_account"
      t.string   "uuid"
      t.timestamps
    end
    add_index :payments, "action"
    add_index :payments, ["payable_id", "payable_type"]
    add_index :payments, "position"
    add_index :payments, "reference"
    add_index :payments, "uuid"
    
    
    #--- gateways
    create_table :gateways do |t|
      t.string "name",            :null => false
      t.string "mode"
      t.string "type"
      t.string "login_id"
      t.string "transaction_key"
      t.timestamps
    end
    add_index :gateways, "name"
    add_index :gateways, "type"
    
  end

  def self.down
    drop_table :gateways
    drop_table :payments
    drop_table :invoices
    drop_table :orders
    drop_table :line_items
  end
end
