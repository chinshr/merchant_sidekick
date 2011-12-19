require "bundler/setup"
require "rspec"
require "active_record"
require "sqlite3"
require "merchant_sidekick"

RSpec.configure do |config|
  # some (optional) config here
end

# If you want to see the ActiveRecord log, invoke the tests using `rake test LOG=true`
if ENV["LOG"]
  require "logger"
  ActiveRecord::Base.logger = Logger.new($stdout)
end

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"
ActiveRecord::Migration.verbose = false

require "schema"
at_exit {ActiveRecord::Base.connection.disconnect!}

#--- MerchantSidekick::Addressable test models
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

def valid_address_attributes(options={})
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
  }.merge(MerchantSidekick::Addressable::Address.middle_name? ? { :middle_name => "W." } : {}).merge(options)
end
