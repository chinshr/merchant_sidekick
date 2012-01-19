require File.expand_path("../spec_helper", __FILE__)

describe "A seller's model" do

  it "should be able to sell" do
    SellingUser.new.should respond_to(:sell)
  end

  it "should be able to sell" do
    SellingUser.new.should respond_to(:sell_to)
  end

  it "should have many orders" do
    lambda { SellingUser.new.orders(true).first }.should_not raise_error
  end

  it "should have many invoices" do
    lambda { SellingUser.new.invoices(true).first }.should_not raise_error
  end

  it "should have many sales orders" do
    lambda { SellingUser.new.sales_orders(true).first }.should_not raise_error
  end

  it "should have many sales invoices" do
    lambda { SellingUser.new.sales_invoices(true).first }.should_not raise_error
  end

end

describe "A seller sells a product" do

  def setup
    @sally          = users(:sally)
    @sally_billing  = @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally_shipping = @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)
    @sam            = users(:sam)
    @sam_billing    = @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping   = @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @product        = products(:widget)
  end

  it "should create a new order" do
    transaction do
      lambda do
        order = @sally.sell_to @sam, @product
        order.should be_an_instance_of(MerchantSidekick::SalesOrder)
        order.buyer.should == @sam
        order.should be_valid
        order.save!
      end.should change(MerchantSidekick::Order, :count)
    end
  end

  it "should build sales order :to option" do
    transaction do
      lambda do
        order = @sally.sell @product, :to => @sam
        order.should be_an_instance_of(MerchantSidekick::SalesOrder)
        order.seller.should == @sally
        order.buyer.should == @sam
        order.should be_valid
        order.save!
      end.should change(MerchantSidekick::Order, :count)
    end
  end

  it "should add to seller's orders" do
    transaction do
      order = @sally.sell_to(@sam, @product)
      order.save!
      @sally.orders.last.should == order
      @sally.sales_orders.last.should == order
      order.seller.should == @sally
      order.buyer.should == @sam
    end
  end

  it "should create line items" do
    transaction do
      order = @sally.sell_to(@sam, @product)
      order.line_items.size.should == 1
      order.line_items.first.sellable.should == @product
    end
  end

  it "should set line item amount to sellable price" do
    transaction do
      order = @sally.sell_to @sam, @product
      order.line_items.first.amount.should == @product.price
    end
  end

  it "should set line item amount to 0 if sellable does not have a price" do
    transaction do
      @product.price = 0
      order = @sally.sell_to @sam, @product
      order.line_items.first.amount.should == 0.to_money
    end
  end

  it "should ignore blank sellables" do
    transaction do
      order = @sally.sell_to @sam, @product, nil
      order.line_items.size.should == 1
    end
  end

end

describe "A seller selling multiple products" do

  def setup
    @sally          = users(:sally)
    @sally_billing  = @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally_shipping = @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)
    @sam            = users(:sam)
    @sam_billing    = @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping   = @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @products       = [products(:widget), products(:knob)]
    @order          = @sally.sell_to @sam, @products
  end

  it "should create line items for each sellable" do
    transaction do
      lambda { @order.save! }.should change(MerchantSidekick::LineItem, :count).by(2)
      @order.should have(2).line_items
      @order.line_items.map(&:sellable).should == @products
    end
  end
end

describe "A seller selling a cart" do

  def setup
    @sally          = users(:sally)
    @sally_billing  = @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally_shipping = @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)
    @sam            = users(:sam)
    @sam_billing    = @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping   = @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @products       = [products(:widget), products(:knob)]
    @order          = @sally.sell_to @sam, @products
    @cart           = MerchantSidekick::ShoppingCart::Cart.new
  end

  it "should sell one cart" do
    transaction do
      @cart.add(@products)
      @cart.total.to_s.should == "33.94"
      order = @sally.sell_to @sam, @cart
      order.total.to_s.should == "33.94"
    end
  end
  
  it "should sell multipe carts" do
    transaction do
      cart1 = MerchantSidekick::ShoppingCart::Cart.new
      cart2 = MerchantSidekick::ShoppingCart::Cart.new
      
      cart1.add(@products.first)
      cart2.add(@products.last)
      order = @sally.sell_to @sam, cart1, cart2
      order.total.to_s.should == "33.94"
    end
  end
  
end


describe "A seller selling no product" do

  def setup
    @sally          = users(:sally)
    @sally_billing  = @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally_shipping = @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)
    @sam            = users(:sam)
    @sam_billing    = @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping   = @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @product        = products(:widget)
  end

  it "should raise an error as sell is a protected method" do
    transaction do
      lambda { @sally.sell(@product) }.should raise_error(NoMethodError)
    end
  end

  it "should raise an error for there is no sellable" do
    transaction do
      lambda { @sally.sell_to(@sam) }.should raise_error(ArgumentError)
    end
  end

  it "should raise an error for no sellable" do
    transaction do
      lambda { @sally.sell_to(@sam, []) }.should raise_error(ArgumentError)
    end
  end

end