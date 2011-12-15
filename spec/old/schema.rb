ActiveRecord::Schema.define :version => 0 do
  execute "SET FOREIGN_KEY_CHECKS = 0"

  #--- addresses
  create_table :addresses, :force => true do |t|
    t.column :addressable_id, :integer, :null => false
    t.column :addressable_type, :string, :null => false
    t.column :type, :string
    t.column :gender, :string
    t.column :street, :text
    t.column :city, :string
    t.column :postal_code, :string
    t.column :province, :string
    t.column :province_code, :string
    t.column :country, :string
    t.column :country_code, :string
    t.column :company_name, :string
    t.column :first_name, :string
    t.column :middle_name, :string
    t.column :last_name, :string
    t.column :note, :text
    t.column :phone, :string
    t.column :mobile, :string
    t.column :fax, :string
    # timestamp
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  add_index :addresses, [:addressable_id, :addressable_type]
  add_index :addresses, :type
  add_index :addresses, :city
  add_index :addresses, :province
  add_index :addresses, :province_code
  add_index :addresses, :country
  add_index :addresses, :country_code
  add_index :addresses, :gender
  add_index :addresses, :first_name
  add_index :addresses, :middle_name
  add_index :addresses, :last_name
  add_index :addresses, :company_name
  add_index :addresses, :phone
  add_index :addresses, :mobile
  add_index :addresses, :fax

  #--- gateways
  create_table :gateways, :force => true do |t|
    t.column :name, :string, :null => false
    t.column :mode, :string
    t.column :type, :string
  end
  add_index :gateways, :name
  add_index :gateways, :type

  #--- invoices
  drop_table :invoices
  create_table :invoices, :force => true do |t|
    t.column :buyer_id, :integer
    t.column :buyer_type, :string
    t.column :seller_id, :integer
    t.column :seller_type, :string
    t.column :net_cents, :integer, :null => false, :default => 0
    t.column :tax_cents, :integer, :null => false, :default => 0
    t.column :gross_cents, :integer, :null => false, :default => 0
    t.column :tax_rate, :float, :null => false, :default => 0.0
    t.column :currency, :string, :null => false, :default => 'USD'
    t.column :type, :string
    t.column :number, :string
    t.column :status, :string, :null => false, :default => 'pending'
    t.column :lock_version, :boolean, :null => false, :default => false
    # timestamp
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
    t.column :paid_at, :datetime
  end
  add_index :invoices, [:buyer_id, :buyer_type]
  add_index :invoices, [:seller_id, :seller_type]
  add_index :invoices, :type
  add_index :invoices, :number
  
  #--- payment
  create_table :payments, :force => true do |t|
    t.column :payable_id, :integer, :null => false  # invoice
    t.column :payable_type, :string, :null => false # invoice 
    t.column :success, :boolean
    t.column :reference, :string
    t.column :message, :string
    t.column :action, :string
    t.column :params, :string
    t.column :test, :boolean
    t.column :cents, :integer, :null => false, :default => 0
    t.column :currency, :string, :null => false, :limit => 3, :default => 'USD'
    t.column :lock_version, :integer, :null => false, :default => 0
    t.column :position, :integer
    t.column :type, :string
    # timestamps
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  add_index :payments, [:payable_id, :payable_type]
  add_index :payments, :reference
  add_index :payments, :message
  add_index :payments, :action
  add_index :payments, :params
  add_index :payments, :position
  
  #--- orders
  create_table :orders, :force => true do |t|
    t.column :buyer_id, :integer
    t.column :buyer_type, :string
    t.column :seller_id, :integer
    t.column :seller_type, :string
    t.column :invoice_id, :integer
    t.column :net_cents, :integer, :null => false, :default => 0
    t.column :tax_cents, :integer, :null => false, :default => 0
    t.column :gross_cents, :integer, :null => false, :default => 0
    t.column :currency, :string, :null => false, :limit => 3, :default => 'USD'
    t.column :tax_rate, :float, :null => false, :default => 0.0
    t.column :type, :string
    t.column :lock_version, :boolean, :null => false, :default => false
    t.column :status, :string, :null => false, :default => 'created'
    t.column :number, :string
    t.column :description, :string
    # timestamp
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
    t.column :canceled_at, :datetime
  end
  add_index :orders, [:buyer_id, :buyer_type]
  add_index :orders, [:seller_id, :seller_type]
  add_foreign_key :orders, :invoice_id, :invoices, :id, :name => :fk_orders_invoices
  add_index :orders, :type
  add_index :orders, :status
  
  #--- line_items
  create_table :line_items, :force => true do |t|
    t.column :order_id, :integer #, :null => false
    t.column :invoice_id, :integer
    t.column :sellable_id, :integer, :null => false
    t.column :sellable_type, :string, :null => false
    t.column :net_cents, :integer, :null => false, :default => 0
    t.column :tax_cents, :integer, :null => false, :default => 0
    t.column :gross_cents, :integer, :null => false, :default => 0
    t.column :currency, :string, :null => false, :limit => 3, :default => 'USD'
    t.column :tax_rate, :float, :null => false, :default => 0.0
    # timestamp
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  add_foreign_key :line_items, :order_id, :orders, :id, :name => :fk_line_items_orders
  add_foreign_key :line_items, :invoice_id, :invoices, :id, :name => :fk_line_items_invoices
  add_index :line_items, [:sellable_id, :sellable_type]

  #--- cart line items
  create_table :cart_line_items, :force => true do |t|
    t.column :item_number, :string
    t.column :name, :string
    t.column :description, :string
    t.column :quantity, :integer, :null => false, :default => 1
    t.column :unit, :string, :null => false, :default => 'piece'
    t.column :pieces, :integer, :null => false, :default => 0
    t.column :cents, :integer, :null => false, :default => 0
    t.column :currency, :string, :null => false, :limit => 3, :default => 'USD'
    t.column :taxable, :boolean, :null => false, :default => false
    t.column :product_id, :integer, :null => false
    t.column :product_type, :string, :null => false
    # timestamp
    t.column :created_at, :datetime
    t.column :updated_at, :datetime
  end
  add_index :cart_line_items, :item_number
  add_index :cart_line_items, :name
  add_index :cart_line_items, :description
  add_index :cart_line_items, :quantity
  add_index :cart_line_items, :unit
  add_index :cart_line_items, :pieces
  add_index :cart_line_items, [:product_id, :product_type]

  #--- product dummy
  create_table :product_dummies, :force => true do |t|
    t.column :title, :string
    t.column :description, :text
    t.column :image_url, :string
    t.column :cents, :integer
    t.column :currency, :string, :null => false, :default => 'USD'
  end
  
  #--- user dummy
  create_table :user_dummies, :force => true do |t|
    t.column :name, :string
    t.column :email, :string
    t.column :type, :string
  end

  execute "SET FOREIGN_KEY_CHECKS = 1"
end