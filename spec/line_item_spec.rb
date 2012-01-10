require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::LineItem do
  it "should belong to an order" do
    lambda { MerchantSidekick::LineItem.new.order}.should_not raise_error
  end

  it "should belong to an invoice" do
    lambda { MerchantSidekick::LineItem.new.invoice}.should_not raise_error
  end

  it "should belong to a sellable model" do
    lambda { MerchantSidekick::LineItem.new.sellable}.should_not raise_error
  end

  it "should have a tax rate class name attribute" do
    lambda { MerchantSidekick::LineItem.tax_rate_class_name}.should_not raise_error
  end

  it "should have a gross amount composed field" do
    lambda { MerchantSidekick::LineItem.new.gross_amount == 0.to_money}.should_not raise_error
  end

  it "should have a tax amount composed field" do
    lambda { MerchantSidekick::LineItem.new.tax_amount == 0.to_money}.should_not raise_error
  end

  it "should have a net amount composed field" do
    lambda { MerchantSidekick::LineItem.new.net_amount == 0.to_money}.should_not raise_error
  end

end

describe MerchantSidekick::LineItem, "a new line item" do

  it "should set #price when setting #sellable" do
    @sellable = Product.new(:price => 10.to_money)
    @line_item = MerchantSidekick::LineItem.new(:sellable => @sellable)
    @line_item.amount.should == @sellable.price
  end

  it "should set #price to 0 when #sellable doesn't have a price" do
    @sellable = Product.new
    @line_item = MerchantSidekick::LineItem.new(:sellable => @sellable)
    @line_item.amount.should == 0.to_money
  end

  it "should return sellable when calling #sellable=" do
    @sellable = Product.new(:title => "Rad New Widget", :price => 10.to_money)
    @line_item = MerchantSidekick::LineItem.new
    sellable = @line_item.sellable=(@sellable)
    sellable.should === @sellable
  end

  it "should save" do
    lambda {
      @product = Product.new(:price => 10.to_money, :title => "Pack of Candles")
      @line_item = MerchantSidekick::LineItem.new(:sellable => @product)
      @line_item.save
      @line_item.reload
      @line_item.amount.should == Money.new(1000, "USD")
    }.should change(MerchantSidekick::LineItem, :count)
  end

end
