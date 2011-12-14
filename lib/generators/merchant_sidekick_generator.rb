require 'rails/generators'
require "rails/generators/active_record"

class MerchantSidekickGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  extend ActiveRecord::Generators::Migration

  source_root File.expand_path('../../merchant_sidekick', __FILE__)

  # Copies the migration template to db/migrate.
  def copy_files(*args)
    migration_template 'billing.rb', 'db/migrate/create_merchant_sidekick_billing_tables.rb'
    migration_template 'shopping_cart.rb', 'db/migrate/create_merchant_sidekick_shopping_cart_tables.rb'
    migration_template 'addressable.rb', 'db/migrate/create_merchant_sidekick_addressable_tables.rb'
  end

end
