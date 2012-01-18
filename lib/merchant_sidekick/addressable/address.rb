module MerchantSidekick
  module Addressable
    # Super class of all types of addresses
    class Address < ActiveRecord::Base
      self.table_name = "addresses"

      #--- column mapping
      cattr_accessor :street_address_column
      @@street_address_column = :street

      cattr_accessor :city_column
      @@city_column = :city

      cattr_accessor :postal_code_column
      @@postal_code_column = :postal_code

      cattr_accessor :province_column
      @@province_column = :province

      cattr_accessor :province_code_column
      @@province_code_column = :province_code

      cattr_accessor :country_column
      @@country_column = :country

      cattr_accessor :country_code_column
      @@country_code_column = :country_code

      cattr_accessor :gender_column
      @@gender_column = :gender

      cattr_accessor :first_name_column
      @@first_name_column = :first_name

      cattr_accessor :middle_name_column
      @@middle_name_column = false

      cattr_accessor :last_name_column
      @@last_name_column = :last_name

      #--- associations
      belongs_to :addressable, :polymorphic => true

      #--- validations
      # extend your Address class with validation as you please

      #--- callbacks

      # This particular call back could be used to save
      # geocordinates if addressable defines :before_save_address method
      def before_save
        # trigger before_save_address
        self.addressable.send(:before_save_address, self) if addressable && addressable.respond_to?(:before_save_address)
      end

      #--- class methods

      class << self

        def kind
          name.underscore
        end

        # Returns the binding to be used in sub classes of Address
        def get_binding
          binding
        end

        # Helper class method to look up all addresss for
        # addressable class name and addressable id.
        def find_address_for_addressable(addressable_str, addressable_id)
          find(:all,
            :conditions => ["addressable_type = ? AND addressable_id = ?", addressable_str, addressable_id],
            :order => "created_at DESC"
          )
        end

        # Helper class method to look up a addressable object
        # given the addressable class name and id
        def find_addressable(addressable_str, addressable_id)
          addressable_str.constantize.find(addressable_id)
        end

        # attempt to make sanitize_sql public
        def sanitize_sql_with_key_translation(condition)
          sanitize_sql_without_key_translation(condition)
        end
        alias_method_chain :sanitize_sql, :key_translation

        # TODO not used
        def translate_column_key(in_column)
          out_column = class_variable_get("@@#{in_column}")
          case out_column.class.name
          when /NilClass/ then in_column
          when /FalseClass/ then nil
          else out_column
          end
        end

        def content_column_names
          content_columns.map(&:name) - %w(kind addressable_type addressable_id updated_at created_at)
        end

      end

      #--- instance methods

      # geokit getter
      # returns a hash of geokit compatible GeoKit::Location attributes
      def geokit_attributes
        {
          :zip => self.postal_code,
          :city => self.city,
          :street_address => self.street_address,
          :state => self.province_code || self.province,
          :country_code => self.country_code
        }
      end

      # geokit setter
      def geokit_attributes=(geo_attr)
        self.attributes = {
          :postal_code => geo_attr[:zip],
          :city => geo_attr[:city],
          :street_address => geo_attr[:street_address],
          :province_code => geo_attr[:state],
          :country_code => geo_attr[:country_code]
        }
      end

      # attributes for active merchant address
      def merchant_attributes(options={})
        {
          :name => self.name,
          :address1 => self.address_line_1,
          :address2 => self.address_line_2,
          :city => self.city,
          :state => (self.province_code || self.province),
          :country => (self.country_code || self.country),
          :zip => self.postal_code,
          :phone => self.phone
        }.merge(options)
      end
      alias_method :to_merchant_attributes, :merchant_attributes

      # getter
      def street
        self[street_address_column]
      end
      alias_method :street_address, :street

      # setter
      def street=(a_street)
        self[street_address_column] = a_street
      end
      alias_method :street_address=, :street=

      # postal_code reader
      def postal_code
        self[postal_code_column]
      end
      alias_method :zip, :postal_code

      # postal_code instead of ZIP
      def postal_code=(a_zip)
        self[postal_code_column] = a_zip
      end
      alias_method :zip=, :postal_code=

      # address_line_1 getter, first line of street_address
      # address1 alias for active merchant
      def address_line_1
        (self.street.gsub(/\r/, '').split(/\n/)[0] || self.street).strip if self.street
      end
      alias_method :address1, :address_line_1

      # setter
      def address_line_1=(addr1)
        self.street = "#{addr1}\n#{address_line_2}"
      end
      alias_method :address1=, :address_line_1=

      # address_line_2 getter, second line and following of street
      # address2 alias for active merchant
      def address_line_2
        self.street.gsub(/\r/, '').split(/\n/)[1] if self.street
      end
      alias_method :address2, :address_line_2

      # setter
      def address_line_2=(addr2)
        self.street = "#{address_line_1}\n#{addr2}"
      end
      alias_method :address2=, :address_line_2=

      # province getter
      def province
        self[province_column]
      end
      alias_method :state, :province

      # province setter
      def province=(a_province)
        self[province_column] = a_province
      end
      alias_method :state=, :province=

      # province code getter
      def province_code
        self[province_code_column] if province_code?
      end

      def self.province_code?
        return true if province_code_column
        false
      end

      def province_code?
        return true if province_code_column
        false
      end

      # province code setter
      def province_code=(a_province_code)
        self[province_code_column] = a_province_code if province_code?
      end

      # country getter
      def country
        self[country_column]
      end

      # country setter
      def country=(a_country)
        self[country_column] = a_country
      end

      # country code getter
      def country_code
        self[country_code_column] if country_code?
      end

      def country_code?
        return true if country_code_column
        false
      end

      # country code setter
      def country_code=(a_country_code)
        self[country_code_column] = a_country_code if country_code?
      end

      # getter
      def first_name
        self[first_name_column] if first_name?
      end
      alias_method :firstname, :first_name

      def first_name?
        return true if first_name_column
        false
      end

      # setter
      def first_name=(a_first_name)
        self[first_name_column] = a_first_name if first_name?
      end
      alias_method :firstname=, :first_name=

      # getter
      def last_name
        self[last_name_column] if last_name?
      end
      alias_method :lastname, :last_name

      def last_name?
        return true if last_name_column
        false
      end

      # setter
      def last_name=(a_last_name)
        self[last_name_column] = a_last_name if last_name?
      end
      alias_method :lastname=, :last_name=

      # getter
      def middle_name
        self[middle_name_column] if middle_name?
      end
      alias_method :middlename, :middle_name

      def self.middle_name?
        return true if middle_name_column
        false
      end

      def middle_name?
        return true if middle_name_column
        false
      end

      # setter
      def middle_name=(a_middle_name)
        self[middle_name_column] = a_middle_name if middle_name?
      end

      # setter
      def gender=(a_gender)
        if gender?
          if a_gender.is_a? Symbol
            self[gender_column] = case a_gender
            when :male then 'm'
            when :female then 'f'
            else ''
            end
          elsif a_gender.is_a? String
            self[gender_column] = case a_gender
            when 'm' then 'm'
            when 'f' then 'f'
            else ''
            end
          end
        end
      end

      # gender getter
      def gender
        self[gender_column] if gender?
      end

      def gender?
        return true if gender_column
        false
      end

      def is_gender_male?
        self.gender == 'm'
      end

      def is_gender_female?
        self.gender == 'f'
      end

      # Concatenates First-, Middle-, last_name to one string
      def name
        result = []
        result << first_name
        result << middle_name
        result << last_name
        result = result.compact.map {|m| m.to_s.strip }.reject {|i| i.empty? }
        return result.join(' ') unless result.empty?
      end

      # Similar as in Person, only displays like "Mr" or "Prof. Dr."
      def salutation(options={})
        (self.is_gender_male? ? (return "Mr") : (return "Ms")) if self.gender
        ''
      end
      alias_method :salutation_display, :salutation

      # Returns the salutation and name, like "Prof. Dr. Thomas Mann" or "Mr Adam Smith"
      def salutation_and_name
        "#{salutation} #{name}".strip
      end
      alias_method :salutation_and_name_display, :salutation_and_name

      # returns the province (as full text) or the province_code (e.g. CA)
      def province_or_province_code
        self.province.to_s.empty? ? self.province_code : self.province
      end

      # returns either the full country name or the country code (e.g. DE)
      def country_or_country_code
        self.country.to_s.empty? ? self.country_code : self.country
      end

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

      # return only attributes with relevant content
      def content_attributes
        self.attributes.reject {|k,v| !self.content_column_names.include?(k.to_s)}.symbolize_keys
      end

      # returns content column name strings
      def content_column_names
        self.class.content_column_names
      end

      # E.g. :billing_addres, :shipping_address
      def kind
        self.class.kind
      end
    end
  end
end
