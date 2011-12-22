require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::Order do

  def setup
    @products   = [products(:widget), products(:knob)]
    @line_items = [line_items(:sams_widget), line_items(:sams_knob)]
    @order      = orders(:sams_widget)
    @order.reload and @order.save
  end
  
  it "should have line_items" do
    lambda { MerchantSidekick::Order.new.line_items.first }.should_not raise_error
  end
  
  it "should calculate amount" do
    transaction do
      lambda {
        @order.net_amount.should == ::Money.new(3394, "USD")
        @order.tax_amount.should == ::Money.new(0)
        @order.gross_amount.should == ::Money.new(3394, "USD")
        @order.total.should == ::Money.new(3394, "USD")
        @order.line_items_count.should == 2
      }.should_not raise_error
    end
  end
  
end

describe MerchantSidekick::Order, "with addresses" do
  def setup
    addresses(:paid_order_billing_address)
    addresses(:paid_order_shipping_address)
    addresses(:paid_order_origin_address)
    orders(:sams_widget)
    @order = orders(:paid)
    @order.reload and @order.save
  end
  
  it "should have billing, shipping and origin address" do
    transaction do
      @order.billing_address.should_not be_nil
      @order.shipping_address.should_not be_nil
      @order.origin_address.should_not be_nil
    end
  end
end

describe "A new order" do
  
  def setup
    @products   = [products(:widget), products(:knob)]
    @line_items = [line_items(:sams_widget), line_items(:sams_knob)]
    @order      = orders(:sams_widget)
    @order.reload and @order.save
  end
  
  it "amount should equal sum of sellables price" do
    transaction do
      @order.net_amount.should == @products.inject(0.to_money) {|sum,p| sum + p.price}
    end
  end
  
end

describe "A new order with purchases" do
  
  def setup
    @user         = users(:sam)
    @sam_billing  = @user.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping = @user.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @product      = products(:widget)
    @order        = @user.purchase @product
  end

  it "should evaluate after pushing a new item" do
    transaction do
      @order.gross_total.should == "29.95".to_money
      lambda { @order.push(products(:knob)) }.should change(@order, :items_count).by(1)
      @order.gross_total.to_s.should == '33.94'
      @order.should be_new_record
    end
  end
  
end
