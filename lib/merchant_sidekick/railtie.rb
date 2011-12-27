module MerchantSidekick
  class Railtie < ::Rails::Railtie
    generators do
      require File.expand_path("../install.rb", __FILE__)
    end
  end
end