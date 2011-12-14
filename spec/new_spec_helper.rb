require "bundler/setup"
require "rspec"
require "active_record"
require "sqlite3"
require "merchant_sidekick"

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

p ActiveRecord::Base.connection


at_exit {ActiveRecord::Base.connection.disconnect!}