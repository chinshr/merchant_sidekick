# Base class for all merchant sidekick gateway implementations.
module MerchantSidekick
  
  class << self
    def default_gateway
      MerchantSidekick::Gateway.default_gateway
    end
    
    def default_gateway=(value)
      MerchantSidekick::Gateway.default_gateway = value
    end
  end
  
  class Gateway
    cattr_accessor :config_path
    cattr_accessor :config_file_name
    @@config_file_name = "merchant_sidekick.yml"
    cattr_accessor :config
    cattr_accessor :default_gateway  # ->  sets default gateway as instance or class (symbol) optional
    cattr_accessor :gateway          # ->  caches gateway instance in decendants, e.g. in PaypalGateway.gateway

    class << self

      # Returns the gateway type name derived from the class name 
      # independent of the module name, e.g. :authorize_net_gateway
      def type
        name.split("::").last ? name.split("::").last.underscore.to_sym : name.underscore.to_sym
      end

      def config_path(file_name = nil)
        unless @@config_path
          @@config_path = "#{Rails.root}/config/#{file_name || config_file_name}"
        end
        @@config_path
      end

      # Returns configuration hash. By default the configuration is read from
      # a YAML file from the Rails config/merchant_sidekick.yml path.
      #
      # E.g.
      #
      #    # config/merchant_sidekick.yml
      #    development:
      #      login_id: foo
      #      transaction_key: bar
      #      mode: test
      #    production:
      #      ...
      #
      # or
      #
      #    # config/merchant_sidekick.yml
      #    development:
      #      authorize_net_gateway:
      #        login_id: foo
      #        transaction_key: bar
      #        mode: test
      #      paypal_gateway:
      #        api_username: seller_XYZ_biz_api1.example.com
      #        api_password: ABCDEFG123456789
      #        signature: AsPC9BjkCyDFQXbStoZcgqH3hpacAX3IenGazd35.nEnXJKR9nfCmJDu
      #        pem_file_name: config/paypal.pem
      #        mode: test
      #    production:
      #      ...
      #
      def config
        unless @@config
          @@config = YAML.load_file(config_path)[Rails.env].symbolize_keys
          @@config = @@config[type].symbolize_keys if @@config[type]
        end
        @@config
      end

      def default_gateway
        @@default_gateway || raise("No gateway instance assigned, try e.g. MerchantSidekick::Gateway.default_gateway = ActiveMerchant::Billing::BogusGateway.new")
      end

    end
  end
end