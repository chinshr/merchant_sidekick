require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
require File.dirname(__FILE__) + '/bogus_gateway_ext'
require 'spec/rails'
include ActiveMerchant::Billing

plugin_spec_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = plugin_spec_dir + '/fixtures'
end

load(File.dirname(__FILE__) + '/schema.rb')

#--- helpers

def valid_address_attributes(options={})
  {
    :first_name => "George",
    :last_name => "Bush",
    :gender => 'm',
    :street => "100 Washington St.",
    :postal_code => "95065",
    :city => "Santa Cruz",
    :province_code => "CA",
    :province => "California",
    :company_name => "Exxon",
    :phone => "+1 831 123-4567",
    :mobile => "+1 831 223-4567",
    :fax => "+1 831 323-4567",
    :country_code => "US",
    :country => "United States of America"
  }.merge(options)
end

def valid_credit_card_attributes(attrs = {})
  {
    :number => "1",
    :first_name => "Claudio",
    :last_name => "Almende",
    :month => "8",
    :year => "#{ Time.now.year + 1 }",
    :verification_value => '123',
    :type => 'visa'
  }.merge(attrs)
end

def invalid_credit_card_attributes(attrs = {})
  {
    :first_name => "first",
    :last_name => "last",
    :month => "8",
    :year => Time.now.year + 1,
    :number => "2",
    :type => "bogus"
  }.merge(attrs)
end

# returns a valid credit card instance
def credit_card(options={})
  ActiveMerchant::Billing::CreditCard.new(valid_credit_card_attributes(options))
end

def valid_credit_card(options={})
  credit_card(valid_credit_card_attributes(options))
end

def invalid_credit_card(options={})
  credit_card(invalid_credit_card_attributes(options))
end

#--- test dummy class definitions
class ProductDummy < ActiveRecord::Base
  money :price
  acts_as_sellable
  
  # weird cart serialization workaround
  def target
    true
  end
  
end

class UserDummy < ActiveRecord::Base
  acts_as_addressable :billing, :shipping
end

class BuyingUser < UserDummy
  acts_as_buyer
end

class SellingUser < UserDummy
  acts_as_seller
end

# extend Address
class Address

  # Writes the address as comma delimited string
  def to_s
    result = []
    result << self.address_line_1
    result << self.address_line_2
    result << self.city
    result << self.province_or_province_code
    result << self.postal_code
    result << self.country_or_country_code
    result.compact.map {|m| m.to_s.strip }.reject {|i| i.empty? }.join(", ")
  end

end