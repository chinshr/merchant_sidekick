require File.dirname(__FILE__) + '/../spec_helper'

describe HasOneSingleAddressModel, "new" do

  before(:each) do
    Address.middle_name_column = false
    @addressable = HasOneSingleAddressModel.new
    @address = @addressable.build_address valid_address_attributes
  end
  
  it "should have an addressable for address" do
    @address.addressable.should_not be_nil
    @address.addressable.should == @addressable
  end
  
end

describe HasOneSingleAddressModel, "create" do

  before(:each) do
    Address.middle_name_column = false
    @addressable = HasOneSingleAddressModel.create
    @address = @addressable.create_address valid_address_attributes
  end
  
  it "should have a single address" do
    @addressable.address.should_not be_nil
    @addressable.address.to_s.should == "George Bush, 100 Washington St., Santa Cruz, California, 95065, United States of America"
  end

end

describe HasManySingleAddressModel do

  before(:each) do
    Address.middle_name_column = false
    @addressable = HasManySingleAddressModel.create
    @address = @addressable.addresses.create valid_address_attributes
  end

  it "should hold at least hold one" do
    @addressable.addresses.should_not be_empty
    @addressable.addresses.size.should == 1
  end

  it "should add more addresses" do
    @addressable.addresses.create valid_address_attributes(
      :first_name => "Barbara", :last_name => "Bush"
    )
    @addressable.addresses.create valid_address_attributes(
      :first_name => "Tom", :last_name => "Bush"
    )
    @addressable.addresses.size.should == 3
    @addressable.addresses[0].to_s.should == "George Bush, 100 Washington St., Santa Cruz, California, 95065, United States of America"
    @addressable.addresses[1].to_s.should == "Barbara Bush, 100 Washington St., Santa Cruz, California, 95065, United States of America"
    @addressable.addresses[2].to_s.should == "Tom Bush, 100 Washington St., Santa Cruz, California, 95065, United States of America"
  end

end

describe HasOneMultipleAddressModel do

  before(:each) do
    Address.middle_name_column = false
    @addressable = HasOneMultipleAddressModel.create
    @billing_address = @addressable.create_billing_address valid_address_attributes(:first_name => "Bill")
    @shipping_address = @addressable.create_shipping_address valid_address_attributes(:first_name => "Ship")
  end

  it "should have a valid billing address" do
    @addressable.billing_address.should_not be_nil
    @addressable.billing_address.should be_billing
    @addressable.billing_address.to_s.should == "Bill Bush, 100 Washington St., Santa Cruz, California, 95065, United States of America"
  end

  it "should populate addressable of an address instance with create" do
    @addressable.billing_address.addressable.should == @addressable
  end

  it "should populate addressable of an address instance with build on an existing" do
    @invoice = HasOneMultipleAddressModel.create
    @invoice.build_billing_address(valid_address_attributes(:first_name => "Bill"))
    @invoice.billing_address.should_not be_nil
    @invoice.billing_address.addressable.should == @invoice
  end

  it "should populate addressable of an address instance with create on an existing" do
    @invoice = HasOneMultipleAddressModel.create
    @invoice.create_billing_address(valid_address_attributes(:first_name => "Bill"))
    @invoice.billing_address.should_not be_nil
    @invoice.billing_address.addressable.should == @invoice
  end

  it "should populate addressable of an address instance with build on a new" do
    @invoice = HasOneMultipleAddressModel.new
    @invoice.build_billing_address(valid_address_attributes(:first_name => "Bill"))
    @invoice.billing_address.should_not be_nil
    @invoice.billing_address.addressable.should == @invoice
  end

  it "should build_shipping_address" do
    customer = HasOneMultipleAddressModel.create
    address = customer.build_shipping_address valid_address_attributes
    customer.shipping_address.should == address
    customer.shipping_address.addressable.should == customer 
  end

  it "should create_shipping_address" do
    addressable = HasOneMultipleAddressModel.create
    lambda {
      address = addressable.create_shipping_address valid_address_attributes
      addressable.shipping_address.should == address
      addressable.shipping_address.addressable.should == addressable 
    }.should change(Address, :count)
  end

  it "should have a valid shipping address" do
    @addressable.shipping_address.should_not be_nil
    @addressable.shipping_address.should be_shipping
    @addressable.shipping_address.to_s.should == "Ship Bush, 100 Washington St., Santa Cruz, California, 95065, United States of America"
  end

  it "should assign a new shipping address" do
    save_billing_address = @addressable.billing_address
    @addressable.billing_address = BillingAddress.new valid_address_attributes(
      :first_name => "New Billing"
    )
    @addressable.save
    @addressable.reload
    save_billing_address.to_s.should_not == @addressable.billing_address
    save_billing_address.id.should_not == @addressable.billing_address.id
    @addressable.billing_address.first_name.should == "New Billing"
  end

  it "should find_addresses" do
    address = @addressable.find_addresses(:all, :billing)
    address.first.should == @billing_address

    address = @addressable.find_addresses(:first, :billing)
    address.should == @billing_address
  end

  it "should find_billing_address" do
    address = @addressable.find_billing_address
    address.should == @billing_address

    address = @addressable.find_billing_address :conditions => @billing_address.content_attributes
    address.should == @billing_address

  end

  it "should find_default_shipping_address and default_shipping_address" do
    @addressable.find_default_shipping_address.should == @shipping_address
    @addressable.default_shipping_address.should == @shipping_address
  end


  it "should find_or_build_shipping_address" do
    # take existing shipping address
    lambda {
      existing_address = @addressable.find_or_build_shipping_address(
        @shipping_address.content_attributes
      )
    }.should_not change(Address, :count)

    # new shipping addresss
    lambda {
      new_address = @addressable.find_or_build_shipping_address(valid_address_attributes(
        :first_name => "New shipping address")
      )
      new_address.should be_new_record
      new_address.should be_shipping
      new_address.first_name.should == "New shipping address"
      new_address.save
    }.should change(Address, :count)
  end

  it "should find_billing_address_or_clone_from" do
    # billing address exists, don't clone
    address = @addressable.find_billing_address_or_clone_from :shipping
    address.should be_instance_of(BillingAddress)
    address.should == @billing_address
    address.street.should == @billing_address.street
    
    # destroy billing address
    lambda {
      @addressable.billing_address.destroy
      @addressable.reload
      @addressable.billing_address.should == nil
    }.should change(Address, :count)

    # clone from new instance
    shipping_address = ShippingAddress.new valid_address_attributes(
      :first_name => "Another Shipping Address"
    )
    lambda {
      cloned_address = @addressable.find_billing_address_or_clone_from shipping_address
      cloned_address.should be_instance_of(BillingAddress)
      cloned_address.should be_billing
      cloned_address.first_name.should == "Another Shipping Address"
      @addressable.save
    }.should change(Address, :count)

    # destroy billing address
    @addressable.billing_address.destroy
    @addressable.reload
    
    # clone from attributes
    shipping_address = ShippingAddress.new valid_address_attributes(
      :first_name => "Yet Another Shipping Address"
    )
    lambda {
      cloned_address = @addressable.find_billing_address_or_clone_from shipping_address.content_attributes
      cloned_address.should be_instance_of(BillingAddress)
      cloned_address.should be_billing
      cloned_address.first_name.should == "Yet Another Shipping Address"
      @addressable.save
    }.should change(Address, :count)
  end
  
end

describe HasManyMultipleAddressModel do

  before(:each) do
    Address.middle_name_column = false
    @addressable = HasManyMultipleAddressModel.create
    @billing_address = @addressable.billing_addresses.create valid_address_attributes(:first_name => "Bill")
    @shipping_address = @addressable.shipping_addresses.create valid_address_attributes(:first_name => "Ship")
  end
  
  it "should have at least one valid billing addresses" do
    @addressable.billing_addresses.should_not be_empty
    @addressable.addresses.size.should == 2
    @addressable.billing_addresses.size.should == 1
    @addressable.billing_addresses.first.should be_billing
    @addressable.billing_addresses.first.should_not be_shipping
    @addressable.billing_addresses.first.to_s.should == "Bill Bush, 100 Washington St., Santa Cruz, California, 95065, United States of America"
  end
  
  it "should have at least one valid shipping addresses" do
    @addressable.shipping_addresses.should_not be_empty
    @addressable.addresses.size.should == 2
    @addressable.shipping_addresses.size.should == 1
    @addressable.shipping_addresses.first.should be_shipping
    @addressable.shipping_addresses.first.should_not be_billing
    @addressable.shipping_addresses.first.to_s.should == "Ship Bush, 100 Washington St., Santa Cruz, California, 95065, United States of America"
  end

end

