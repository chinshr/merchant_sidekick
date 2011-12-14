class CreateMerchantSidekickShoppingCartTables < ActiveRecord::Migration
  def self.up
    create_table "cart_line_items" do |t|
      t.string   "item_number"
      t.string   "name"
      t.string   "description"
      t.integer  "quantity",                  :default => 1,       :null => false
      t.string   "unit",                      :default => "piece", :null => false
      t.integer  "pieces",                    :default => 0,       :null => false
      t.integer  "cents",                     :default => 0,       :null => false
      t.string   "currency",     :limit => 3, :default => "USD",   :null => false
      t.boolean  "taxable",                   :default => false,   :null => false
      t.integer  "product_id",                                     :null => false
      t.string   "product_type",                                   :null => false
      t.datetime "created_at"
      t.datetime "updated_at"
    end
    add_index "cart_line_items", "item_number"
    add_index "cart_line_items", "name"
    add_index "cart_line_items", "unit"
    add_index "cart_line_items", "pieces"
    add_index "cart_line_items", ["product_id", "product_type"]
    add_index "cart_line_items", "quantity"
  end

  def self.down
    drop_table :cart_line_items
  end
end
