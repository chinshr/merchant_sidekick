require File.expand_path("../spec_helper", __FILE__)

describe "A sellable model" do

  it "should have a price" do
    lambda { Product.new.should.respond_to?(:price) }.should_not raise_error
  end

  it "should have many line_items" do
    lambda { Product.new.line_items.should == [] }.should_not raise_error
  end

  it "should have many orders" do
    lambda { Product.new.orders.should == [] }.should_not raise_error
  end

end

describe "A sellable with money" do

  it "should have a currency accessor" do
    lambda {
      Product.new.should.respond_to?(:price_cents)
      Product.new.should.respond_to?(:price_currency)
      Product.new.price_currency.should == "USD"
      Product.new.currency.should == ::Money::Currency.wrap("USD")
    }.should_not raise_error
  end

  it "should have a currency as string accessor" do
    lambda { Product.new.currency_as_string.should == "USD" }.should_not raise_error
  end

end