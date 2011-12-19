class CreateMerchantSidekickAddressableTables < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.integer  "addressable_id"
      t.string   "addressable_type"
      t.integer  "academic_title_id"
      t.string   "gender",            :limit => 1
      t.string   "first_name"
      t.string   "middle_name"
      t.string   "last_name"
      t.text     "street"
      t.string   "city"
      t.string   "postal_code"
      t.string   "province"
      t.string   "province_code",     :limit => 2
      t.string   "country"
      t.string   "country_code",      :limit => 2
      t.string   "company_name"
      t.text     "note"
      t.string   "phone"
      t.string   "mobile"
      t.string   "fax"
      t.string   "type"
    end

    add_index :addresses, ["academic_title_id"], :name => "index_addresses_on_academic_title_id"
    add_index :addresses, ["addressable_id", "addressable_type"], :name => "fk_addresses_addressable"
    add_index :addresses, ["city"], :name => "index_addresses_on_city"
    add_index :addresses, ["company_name"], :name => "index_addresses_on_company_name"
    add_index :addresses, ["country"], :name => "index_addresses_on_country"
    add_index :addresses, ["country_code"], :name => "index_addresses_on_country_code"
    add_index :addresses, ["fax"], :name => "index_addresses_on_fax"
    add_index :addresses, ["first_name"], :name => "index_addresses_on_first_name"
    add_index :addresses, ["gender"], :name => "index_addresses_on_gender"
    add_index :addresses, ["last_name"], :name => "index_addresses_on_last_name"
    add_index :addresses, ["middle_name"], :name => "index_addresses_on_middle_name"
    add_index :addresses, ["mobile"], :name => "index_addresses_on_mobile"
    add_index :addresses, ["phone"], :name => "index_addresses_on_phone"
    add_index :addresses, ["province"], :name => "index_addresses_on_state"
    add_index :addresses, ["province_code"], :name => "index_addresses_on_state_code"
    add_index :addresses, ["type"], :name => "index_addresses_on_type"
  end

  def self.down
    drop_table :addresses
  end
end
