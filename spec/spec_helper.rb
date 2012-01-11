require "bundler/setup"
require "rspec"
require "active_record"
require "active_support"
require "sqlite3"
require "merchant_sidekick"

RSpec.configure do |config|
#  config.use_transactional_fixtures = true
#  config.use_instantiated_fixtures  = false
#  config.fixture_path               = File.dirname(__FILE__) + '/fixtures'
end

# If you want to see the ActiveRecord log, invoke the tests using `rake test LOG=true`
if ENV["LOG"]
  require "logger"
  ActiveRecord::Base.logger = Logger.new($stdout)
end

# Provide basic Rails methods for testing purposes
unless defined?(Rails)
  module Rails
    extend self
    def env; "test"; end
    def root; Pathname.new(File.expand_path("..", __FILE__)); end
  end
end

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
ActiveRecord::Migration.verbose = false

require "schema"
at_exit {ActiveRecord::Base.connection.disconnect!}

Money.default_currency = Money::Currency.wrap("USD")

#--- Sudo fixtures

def transaction
  ActiveRecord::Base.connection.transaction do
    send(:setup) if respond_to?(:setup)
    yield
    raise ActiveRecord::Rollback
  end
end

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

class Addressable < ActiveRecord::Base; end

class HasOneSingleAddressModel < Addressable
  has_address
end

class HasManySingleAddressModel < Addressable
  has_addresses
end

class HasOneMultipleAddressModel < Addressable
  has_address :billing, :shipping
end

class HasManyMultipleAddressModel < Addressable
  has_addresses :billing, :shipping
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
  has_address :billing, :shipping
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

#--- ActiveMerchant related helpers

def valid_credit_card_attributes(attributes = {})
  {
    :number             => "1", #"4242424242424242",
    :first_name         => "Claudio",
    :last_name          => "Almende",
    :month              => "8",
    :year               => "#{ Time.now.year + 1 }",
    :verification_value => '123',
    :type               => 'visa'
  }.merge(attributes)
end

def invalid_credit_card_attributes(attributes = {})
  {
    :first_name => "Bad",
    :last_name  => "Boy",
    :month      => "8",
    :year       => Time.now.year + 1,
    :number     => "2",
    :type       => "bogus"
  }.merge(attributes)
end

def credit_card(options={})
  ActiveMerchant::Billing::CreditCard.new(valid_credit_card_attributes(options))
end

def valid_credit_card(options={})
  credit_card(valid_credit_card_attributes(options))
end

def invalid_credit_card(options={})
  credit_card(invalid_credit_card_attributes(options))
end

module ActiveMerchant
  module Billing
    class BogusGateway < Gateway

      # Transfers money to one or multiple recipients (bulk transfer).
      #
      # Overloaded activemerchant bogus gateways to support transfers, similar
      # to Paypal Website Payments Pro functionality.
      #
      # E.g.
      #
      #   @gateway.transfer 1000, "bob@example.com",
      #     :subject => "The money I owe you", :note => "Sorry, it's coming in late."
      #
      #   gateway.transfer [1000, 'fred@example.com'],
      #     [2450, 'wilma@example.com', :note => 'You will receive an extra payment on March 24.'],
      #     [2000, 'barney@example.com'],
      #     :subject => "Salary January.", :note => "Thanks for your hard work."

      def transfer(money, paypal_account, options={})
        if paypal_account == 'fail@error.tst'
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money.to_s, :error => FAILURE_MESSAGE },:test => true)
        elsif paypal_account == 'error@error.tst'
          raise Error, ERROR_MESSAGE
        elsif /[\w-]+(?:\.[\w-]+)*@(?:[\w-]+\.)+[a-zA-Z]{2,7}$/i.match(paypal_account)
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money.to_s}, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end

    end
  end
end

ActiveMerchant::Billing::Base.mode = :test
ActiveMerchant::Billing::CreditCard.require_verification_value = true

MerchantSidekick::default_gateway = :bogus_gateway