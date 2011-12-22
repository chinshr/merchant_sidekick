require "bundler/setup"
require "rspec"
require "active_record"
require "active_support"
require "sqlite3"
require "merchant_sidekick"
require "ruby-debug"

RSpec.configure do |config|
#  config.use_transactional_fixtures = true
#  config.use_instantiated_fixtures  = false
#  config.fixture_path = File.dirname(__FILE__) + '/fixtures'
end

# If you want to see the ActiveRecord log, invoke the tests using `rake test LOG=true`
if ENV["LOG"]
  require "logger"
  ActiveRecord::Base.logger = Logger.new($stdout)
end

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
ActiveRecord::Migration.verbose = false

def migration
  yield ActiveRecord::Migration
end

def transaction
  ActiveRecord::Base.connection.transaction do
    send(:setup) if respond_to?(:setup)
    yield
    raise ActiveRecord::Rollback
  end
end

require "schema"
at_exit {ActiveRecord::Base.connection.disconnect!}

#--- Fixture surrogates
def users(key, options = {})
  values = YAML::load_file(File.expand_path("../fixtures/users.yml", __FILE__))
  (values[key.to_s]["type"] || "User").constantize.create! values[key.to_s].merge(options)
end

def products(key, options = {})
  values = YAML::load_file(File.expand_path("../fixtures/products.yml", __FILE__))
  (values[key.to_s]["type"] || "Product").constantize.create! values[key.to_s].merge(options)
end

def addresses(key, options = {})
  values = YAML::load_file(File.expand_path("../fixtures/addresses.yml", __FILE__))
  (values[key.to_s]["type"] || "MerchantSidekick::Addressable::Address").constantize.create! values[key.to_s].merge(options)
end

def orders(key, options = {})
  values = YAML::load_file(File.expand_path("../fixtures/orders.yml", __FILE__))
  (values[key.to_s]["type"] || "MerchantSidekick::Order").constantize.create! values[key.to_s].merge(options)
end

def payments(key, options = {})
  values = YAML::load_file(File.expand_path("../fixtures/payments.yml", __FILE__))
  (values[key.to_s]["type"] || "MerchantSidekick::Payment").constantize.create! values[key.to_s].merge(options)
end

def line_items(key, options = {})
  values = YAML::load_file(File.expand_path("../fixtures/line_items.yml", __FILE__))
  (values[key.to_s]["type"] || "MerchantSidekick::LineItem").constantize.create! values[key.to_s].merge(options)
end

#--- MerchantSidekick::Addressable test models

class MerchantSidekick::Addressable::Address
  # extends to_s to add name for testing purposes
  def to_s_with_name
    name = []
    name << self.first_name
    name << self.middle_name if MerchantSidekick::Addressable::Address.middle_name?
    name << self.last_name
    name = name.reject(&:blank?).join(" ")
    [name, to_s_without_name].reject(&:blank?).join(", ")
  end
  alias_method_chain :to_s, :name
end

class Addressable < ActiveRecord::Base
end

class HasOneSingleAddressModel < Addressable
  acts_as_addressable :has_one => true
end

class HasManySingleAddressModel < Addressable
  acts_as_addressable :has_many => true
end

class HasOneMultipleAddressModel < Addressable
  acts_as_addressable :billing, :shipping, :has_one => true
end

class HasManyMultipleAddressModel < Addressable
  acts_as_addressable :billing, :shipping, :has_many => true
end

def valid_address_attributes(attributes = {})
  {
    :first_name    => "George",
    :last_name     => "Bush",
    :gender        => 'm',
    :street        => "100 Washington St.",
    :postal_code   => "95065",
    :city          => "Santa Cruz",
    :province_code => "CA",
    :province      => "California",
    :company_name  => "Exxon",
    :phone         => "+1 831 123-4567",
    :mobile        => "+1 831 223-4567",
    :fax           => "+1 831 323-4567",
    :country_code  => "US",
    :country       => "United States of America"
  }.merge(MerchantSidekick::Addressable::Address.middle_name? ? { :middle_name => "W." } : {}).merge(attributes)
end

#--- MerchantSidekick generic test models

class Product < ActiveRecord::Base
  money :price, :cents => :price_cents, :currency => :price_currency
  acts_as_sellable
  
  # TODO weird cart serialization workaround
  def target; true; end
end

class ProductWithNameAndSku < Product
  def name; "A beautiful name"; end
  def sku; "PR1234"; end
  def description; "Wonderful name!"; end
  def taxable; true; end
end

class ProductWithTitleAndNumber < Product
  def title; "A beautiful title"; end
  def number; "PR1234"; end
  def description; "Wonderful title!"; end
  def new_record?; true; end
end

class ProductWithCopy < Product
  def copy_name(options={}); "customized name"; end
  def copy_item_number(options = {}); "customized item number"; end
  def copy_description(options = {}); "customized description"; end
  def copy_price(options = {}); Money.new(9999, "USD"); end
end

class User < ActiveRecord::Base
  acts_as_addressable :billing, :shipping
end

# TODO rename to just "Buyer"
class BuyingUser < User
  acts_as_buyer
end

# TODO rename to just "Seller"
class SellingUser < User
  acts_as_seller
end

#--- MerchantSidekick shopping cart

def valid_cart_line_item_attributes(attributes = {})
  {:quantity => 5}.merge(attributes)
end

