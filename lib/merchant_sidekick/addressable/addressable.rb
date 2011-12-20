module MerchantSidekick #:nodoc:
  module Addressable #:nodoc:

    def self.included(base)
      base.extend ClassMethods  
    end

    # acts_as_addressable was modified to change behavior in the 
    # following ways:
    #   * supports multiple types (kinds) of addresses
    #   * associations for each kind
    #   * allows additional funtionality
    # Usage:
    #   acts_as_addressable :personal, :business, :billing [, :has_many => true ]
    #     adds methods to find_personal_address or find_or_build_personal_address
    #     as well as associations <addressable>.personal_addresses
    #   acts_as_addressable :mailing, :has_one => true
    #     defines a has_one relationships with is called mailing
    #   acts_as_addressable :personal, :business, :billing, :has_one => true
    #     defines personal_address, etc.
    module ClassMethods
      def acts_as_addressable(*arguments)
        attributes = []
        options = {:has_one => true, :has_many => false}

        # distinguish between options and attributes
        arguments.each do |argument|
          case argument.class.name
          when 'Hash'
            options = { :has_many => false, :has_one => false }.merge(argument)
          else
            case argument
            when :has_many
              options.merge!({ :has_many => true, :has_one => false })
            when :has_one
              options.merge!({ :has_one => true, :has_many => false })
            else
              attributes << argument
            end
          end
        end

        if options[:has_one]
          # acts_as_addressable :has_one => true
          #
          if attributes.empty?
            has_one :address, :as => :addressable, :dependent => :destroy, 
              :class_name => "MerchantSidekick::Addressable::Address"
            
            class_eval <<-THIS
            
              def build_address_with_addressable(options={})
                build_address_without_addressable(options.merge(:addressable => self))
              end
              alias_method_chain :build_address, :addressable
            
              def address_attributes=(attributes)
               self.address ? self.address.attributes = attributes : self.build_address(attributes)
              end
            
            THIS
          else
            # acts_as_addressable :personal, :billing
            attributes.each do |attribute|
              # Address decendent
              # Note: the <attribute>.pluralize.classify makes sure that classify works
              #       for singular attribute, e.g. :business -> BusinessAddress, otherwise,
              #       Rails default would inflect :business -> BusinesAddress
              address_class = <<-ADDRESS
                class #{attribute.to_s.pluralize.classify}Address < MerchantSidekick::Addressable::Address
                  def self.kind
                    '#{attribute}'.to_sym
                  end

                  #{ attributes.collect {|a| "def self.#{a}?; #{a == attribute ? 'true' : 'false'}; end" }.join("\n") }

                  def kind
                    '#{attribute}'.to_sym
                  end

                  #{ attributes.collect {|a| "def #{a}?; #{a == attribute ? 'true' : 'false'}; end" }.join("\n") }
                end
              ADDRESS
              eval address_class, TOPLEVEL_BINDING
              
              has_one "#{attribute}_address".to_sym,
                :class_name => "#{attribute.to_s.pluralize.classify}Address",
                :as => :addressable,
                :dependent => :destroy

              class_eval <<-THIS
              
                def build_#{attribute}_address_with_addressable(options={})
                  build_#{attribute}_address_without_addressable(options.merge(:addressable => self))
                end
                alias_method_chain :build_#{attribute}_address, :addressable
              
                def find_#{attribute}_address(options={})
                  find_address(:#{attribute}, options)
                end
              
                def find_default_#{attribute}_address
                  find_default_address(:#{attribute})
                end
                alias_method :default_#{attribute}_address, :find_default_#{attribute}_address

                def find_or_build_#{attribute}_address(options={})
                  find_or_build_address(:#{attribute}, options)
                end
              
                def find_#{attribute}_address_or_clone_from(from_address, options={})
                  find_or_clone_address(:#{attribute}, from_address, options)
                end
                
                def #{attribute}_address_attributes=(attributes)
                 self.#{attribute}_address ? self.#{attribute}_address.attributes = attributes : self.build_#{attribute}_address(attributes)
                end
              THIS
            end
          end
        elsif options[:has_many]
          # acts_as_addressable :billing, :shipping, :has_many => true
          #
          has_many :addresses, :as => :addressable, :dependent => :destroy,
            :class_name => "MerchantSidekick::Addressable::Address"
            
          attributes.each do |attribute|
            address_class = <<-ADDRESS
              class #{attribute.to_s.pluralize.classify}Address < MerchantSidekick::Addressable::Address
                def self.kind
                  '#{attribute}'.to_sym
                end

                #{ attributes.collect {|a| "def self.#{a}?; #{a == attribute ? 'true' : 'false'}; end" }.join("\n") }

                def kind
                  '#{attribute}'.to_sym
                end

                #{ attributes.collect {|a| "def #{a}?; #{a == attribute ? 'true' : 'false'}; end" }.join("\n") }
              end
            ADDRESS
            eval address_class, TOPLEVEL_BINDING
            
            has_many "#{attribute.to_s.classify}Address".pluralize.underscore.to_sym,
              :class_name => "#{attribute.to_s.pluralize.classify}Address",
              :as => :addressable,
              :dependent => :destroy

            class_eval <<-THIS
              def find_#{attribute}_addresses(options={})
                find_addresses(:all, :#{attribute}, options)
              end

              def find_default_#{attribute}_address
                find_default_address(:#{attribute})
              end
              alias_method :default_#{attribute}_address, :find_default_#{attribute}_address
            
              def find_or_build_#{attribute}_address(options={})
                find_or_build_address(:#{attribute}, options)
              end
            
              def find_#{attribute}_address_or_clone_from(from_address, options={})
                find_or_clone_address(:#{attribute}, from_address, options)
              end
            THIS
          end
        end

        # write options
        write_inheritable_attribute(:acts_as_addressable_options, {
          :association_type => options[:has_one] ? :has_one : :has_many,
          :attributes => attributes
        })
        class_inheritable_reader :acts_as_addressable_options

        include MerchantSidekick::Addressable::InstanceMethods
        extend MerchantSidekick::Addressable::SingletonMethods
      end
    end
  
    # This module contains class methods
    module SingletonMethods

      # Helper method to lookup for addresses for a given object.
      # Example:
      #   Address.find_address_for a_customer_instance
      def find_all_addresses_for(obj)
        addressable = ActiveRecord::Base.send(:class_name_of_active_record_descendant, self).to_s
        Address.find(
          :all,
          :conditions => ["addressable_id = ? AND addressable_type = ?", obj.id, addressable]
        )
      end

    end
  
    # This module contains instance methods
    module InstanceMethods

      # addressable.find_addresses(:first, :billing, conditions)
      def find_addresses(selector, kind, options = {})
        defaults = {:order => "created_at DESC"}
        options = defaults.merge(options).symbolize_keys
        
        if :has_one == acts_as_addressable_options[:association_type]
          conditions = options[:conditions] || ''
          scoped = Address.scoped
          scoped = scoped.where("addressable_id = ? AND addressable_type = ? AND type LIKE ?",
            self.id, self.class.base_class.name, "#{kind.to_s.pluralize.classify}Address")
          scoped = scoped.where(conditions) unless conditions.blank?
          options.merge!(:conditions => conditions)
          scoped.send(selector)
        elsif :has_many == acts_as_addressable_options[:association_type]
          self.send("#{kind}_addresses").find(selector, options)
        end
      end

      def find_address(kind, options={})
        find_addresses(:first, kind, options)
      end

      # returns the default address for either :has_one or :has_many
      # address definitions
      # Usage:
      #   find_default_address :billing
      #
      def find_default_address(kind=nil)
        kind ||= auto_kind
        kind = kind.to_sym
        if :has_one == acts_as_addressable_options[:association_type]
          if acts_as_addressable_options[:attributes].empty?
            self.address
          else
            self.send("#{kind}_address")
          end
        elsif :has_many == acts_as_addressable_options[:association_type]
          if acts_as_addressable_options[:attributes].empty?
            self.addresses.find(:first, :order => "udpated_at DESC")
          else
            self.send("#{kind}_addresses").find(:first, :order => "udpated_at DESC")
          end
        end
      end
      
      # Find address of kind 'type' or instantiate a new address to relationship.
      # Optionally, submit attributes to instantiate the address with.
      # Examples:
      #   find_or_build_address :business
      #   find_or_build_address :business, :street => "100 Infinity Loop"
      #   find_or_build_address :street => "100 Infinity Loop"
      def find_or_build_address(*args)
        options = {}
        attributes = []
        # if first argument, it determines the type => :kind
        args.each do |argument|
          case argument.class.name
          when /Symbol/, /String/
            attributes << argument
          when /Hash/
            options.merge!( argument )
          end
        end
        kind = attributes.first
        unless address = find_address(kind, :conditions => options)
          if :has_one == acts_as_addressable_options[:association_type]
            if acts_as_addressable_options[:attributes].empty?
              address = self.build_address(options)
            else
              address = self.send("build_#{kind}_address", options)
            end
          else
            if acts_as_addressable_options[:attributes].empty?
              address = self.addresses.build(options)
            else
              address = self.send("#{kind}_addresses").build(options)
            end
          end
        end
        address
      end

      # Used for finding the billing address if none is present
      # the billing address is cloned from business address and 
      # if that is not found then a new billing address is created
      # Usage:
      #   find_or_clone_address :billing, an_address, { :company_name => "Bla Inc." }
      # or
      #   find_or_clone_address :billing, :shipping   # finds billing or copies from shipping address
      #
      def find_or_clone_address(to_type, from_address=nil, options={})
        unless to_address = find_default_address(to_type)
          if from_address.nil?
            from_address = "#{to_type}_address".camelize.constantize.new(options)
          elsif from_address.is_a? Symbol
            from_address = find_default_address(from_address)
          elsif from_address.is_a? Hash
            from_address = "#{to_type}_address".camelize.constantize.new(from_address)
          end
          if from_address
            if :has_one == acts_as_addressable_options[:association_type]
              to_address = self.send("build_#{to_type}_address", from_address.content_attributes)
            elsif :has_many == acts_as_addressable_options[:association_type]
              to_address = self.send("#{to_type}_addresses").build from_address.content_attributes
            end
          end
        end
        to_address
      end

    private
    
      def auto_kind
        if :has_one==acts_as_addressable_options[:association_type]
          if acts_as_addressable_options[:attributes].empty?
            :address
          else
            acts_as_addressable_options[:attributes].first
          end
        else
          acts_as_addressable_options[:attributes].first
        end
      end

    end
  
  end
end
