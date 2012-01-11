# Base class for all gatway implementations. The premise is that the gatway
# class accessor Gatway.gateway can either be configured from an environment file
# or if not, it can be defined inside the DB table using the Name column.
# The name column will infer the configuration file which must reside inside
# the rails config/ folder is named after the gateway name, such as
# config/authorize_net.yml
#
module MerchantSidekick
  module Gateways
    class Gateway < ActiveRecord::Base
      self.table_name = "gateways"

      cattr_accessor :source           # -> set to :db or :yaml
      @@source = :yaml
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
          @@default_gateway || raise("No gateway instance assigned, e.g. MerchantSidekick::Gateways::Gateway.default_gateway = ActiveMerchant::Billing::BogusGateway.new")
        end

      end

      # symbolizes name column string such as
      # e.g. 'authorize_net', 'Authorize Net', 'authorize.net' all to :authorize_net
      def service_name
        self[:name].gsub(/\.|,/, '_').gsub(/\s/, '').underscore.to_sym if self[:name]
      end

      def config_file_name
        "#{self.service_name}.yml"
      end

      # returns the gateway instance specified by name stored in the DB, where:
      #
      #   DB NAME column         Class Name              Config File Name        Service Name
      #   'authorize_net'        AuthorizeNetGateway     authorize_net.yml       :authorize_net
      #   'Authorize.net'        dito                    ...                     ...
      #
      # TODO should be refactored to 'instance'
      #
      def gateway
        begin
          "#{self.service_name}Gateway".classify.gateway(self.config_file_name)
        rescue
          self.class.gateway(self.config_file_name)
        end
      end

    end
  end
end