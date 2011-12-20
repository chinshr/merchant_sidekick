require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::Addressable::Address, "should handle default columns" do
  it "should have default class attr columns assigned" do
    MerchantSidekick::Addressable::Address.street_address_column.should == :street 
    MerchantSidekick::Addressable::Address.city_column.should == :city
    MerchantSidekick::Addressable::Address.postal_code_column.should == :postal_code
    MerchantSidekick::Addressable::Address.province_column.should  == :province
    MerchantSidekick::Addressable::Address.province_code_column.should == :province_code
    MerchantSidekick::Addressable::Address.country_column.should == :country
    MerchantSidekick::Addressable::Address.country_code_column.should  == :country_code
    MerchantSidekick::Addressable::Address.gender_column.should == :gender
    MerchantSidekick::Addressable::Address.first_name_column.should == :first_name
    MerchantSidekick::Addressable::Address.middle_name_column.should == false
    MerchantSidekick::Addressable::Address.last_name_column.should == :last_name
  end
end

describe MerchantSidekick::Addressable::Address, "with address members" do
  
  before(:each) do
    @address = MerchantSidekick::Addressable::Address.new(valid_address_attributes(:addressable => Addressable.create))
  end
  
  it "should create an address" do
    @address.should_not == nil
    @address.first_name.should == "George"
    @address.firstname.should == "George"
    @address.middle_name.should == "W." if @address.middle_name?
    @address.last_name.should == "Bush"
    @address.lastname.should == "Bush"
  end 
  
  it "should handle street and address_line" do
    @address.street.should == "100 Washington St."
    @address.address_line_1.should == "100 Washington St."
  end

  it "should add address_line_2 properly" do
    @address.street.should == "100 Washington St."
    @address.address_line_2 = "Suite 1234"
    @address.address_line_2.should == "Suite 1234"
    @address.street.should == "100 Washington St.\nSuite 1234"
  end

  it "should address_line_1 and address_line_2 properly" do
    @address.street = ''
    @address.address_line_1 = "100 Enterprise Way"
    @address.address_line_2 = "Office Square 15"
    
    @address.address_line_1.should == "100 Enterprise Way"
    @address.address_line_2.should == "Office Square 15"
    @address.street.should == "100 Enterprise Way\nOffice Square 15"
  end

  it "should have a valid name" do
    if @address.middle_name?
      @address.name.should == "George W. Bush"
    else
      @address.name.should == "George Bush"
    end
  end
  
  it "should have a valid salutation and name" do
    if @address.middle_name?
      @address.salutation_and_name.should  == "Mr George W. Bush"
    else
      @address.salutation_and_name.should == "Mr George Bush"
    end
  end

  it "should stringify address fields" do
    # full
    @address.to_s.should == "George Bush, 100 Washington St., Santa Cruz, California, 95065, United States of America"
    
    # sparse
    @address = MerchantSidekick::Addressable::Address.new(
      :street        => "100 Sunshine Blvd.",
      :postal_code   => '95066',
      :city          => 'Scotts Valley',
      :province_code => 'CA',
      :country_code  => 'US'
    )
    @address.to_s.should == "100 Sunshine Blvd., Scotts Valley, CA, 95066, US"
  end
  
  it "should return a name" do
    @address.name.should == 'George Bush'
  end  
  
  it "should return nil if names are nil" do
    @address = MerchantSidekick::Addressable::Address.new
    @address.name.should be_nil
  end
  
  it "should convert to active merchant address attributes" do
    @address = MerchantSidekick::Addressable::Address.new(valid_address_attributes(
      :addressable => Addressable.create,
      :street => "100 Sunshine Blvd.\nSuite 7"
    ))
    merchant = @address.to_merchant_attributes
    merchant[:name].should == "George Bush"
    merchant[:address1].should == "100 Sunshine Blvd."
    merchant[:address2].should == "Suite 7"
    merchant[:city].should == "Santa Cruz"
    merchant[:state].should == "CA"
    merchant[:country].should == "US"
    merchant[:zip].should == "95065"
    merchant[:phone].should == "+1 831 123-4567"
  end
  
  it "should work with gender" do
    @address.should be_gender  # funny :-)
    @address.gender = :male
    @address.gender.should == 'm'
    @address.should be_is_gender_male
    @address.gender = :female
    @address.gender.should == 'f'
    @address.gender = 'm'
    @address.gender.should == 'm'
    @address.gender = 'f'
    @address.gender.should == 'f'
  end
  
  it "should return a province or a province code" do
    address = MerchantSidekick::Addressable::Address.new(:province => "California", :province_code => "CA" )
    address.province_or_province_code.should == "California"
    
    address = MerchantSidekick::Addressable::Address.new(:province_code => "CA" )
    address.province_or_province_code.should == "CA"
    
    address = MerchantSidekick::Addressable::Address.new(:province => "", :province_code => "CA" )
    address.province_or_province_code.should == "CA"
    
    address = MerchantSidekick::Addressable::Address.new
    address.province_or_province_code.should be_nil
  end
  
  it "should return a country or a country code" do
    address = MerchantSidekick::Addressable::Address.new(:country => 'Germany', :country_code => 'DE')
    address.country_or_country_code.should == "Germany"

    address = MerchantSidekick::Addressable::Address.new(:country_code => 'DE')
    address.country_or_country_code.should == "DE"

    address = MerchantSidekick::Addressable::Address.new(:country => '', :country_code => 'DE')
    address.country_or_country_code.should == "DE"

    address = MerchantSidekick::Addressable::Address.new
    address.country_or_country_code.should be_nil
  end
  
end
