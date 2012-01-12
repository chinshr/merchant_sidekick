require File.expand_path("../spec_helper", __FILE__)

describe "A buyer's model" do

  it "should be able to purchase" do
    BuyingUser.new.should respond_to(:purchase)
  end

  it "should be able to purchase" do
    BuyingUser.new.should respond_to(:purchase_from)
  end

  it "should have many orders" do
    lambda { BuyingUser.new.orders(true).first }.should_not raise_error
  end

  it "should have many invoices" do
    lambda { SellingUser.new.invoices(true).first }.should_not raise_error
  end

  it "should have many purchase orders" do
    lambda { BuyingUser.new.purchase_orders(true).first }.should_not raise_error
  end

  it "should have many purchase invoices" do
    lambda { BuyingUser.new.purchase_invoices(true).first }.should_not raise_error
  end

end

describe "A buyer purchasing a sellable" do

  def setup
    @user = users(:sam)
    @billing = @user.create_billing_address(addresses(:sam_billing).content_attributes)
    @shipping = @user.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @product = products(:widget)
  end

  it "should create a new order" do
    transaction do
      lambda {
        order_count = MerchantSidekick::Order.count
        order = @user.purchase @product
        order.should be_an_instance_of(MerchantSidekick::PurchaseOrder)
        order.buyer.should be_an_instance_of(BuyingUser)
        order.should be_valid
        order.save!
      }.should change(MerchantSidekick::Order, :count)
    end
  end

  it "should add to buyers's orders" do
    transaction do
      order = @user.purchase(@product)
      order.save!
      @user.orders.last.should == order
      order.buyer.should == @user
    end
  end

  it "should create line items" do
    transaction do
      order = @user.purchase(@product)
      order.line_items.size.should == 1
      order.line_items.first.sellable.should == @product
    end
  end

  it "should set line item amount to sellable price" do
    transaction do
      order = @user.purchase @product
      order.line_items.first.amount.should == @product.price
    end
  end

  it "should set line item amount to 0 if sellable does not have a price" do
    transaction do
      @product.price = 0
      order = @user.purchase @product
      order.line_items.first.amount.should == 0.to_money
    end
  end

  it "should initialize but not save the order" do
    transaction do
      @order = @user.purchase @product
      @order.should be_new_record
    end
  end

end

describe "A buyer purchasing multiple sellables" do

  def setup
    @sally = users(:sally)
    @sally_billing = @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally_shipping = @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)

    @sam = users(:sam)
    @sam_billing = @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping = @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)

    @products = [products(:widget), products(:knob)]
    @order = @sam.purchase_from @sally, @products
  end

  it "should create line items for each sellable" do
    transaction do
      lambda { @order.save! }.should change(MerchantSidekick::LineItem, :count).by(2)
      @order.should have(2).line_items
      @order.line_items.map(&:sellable).should == @products
    end
  end

end

describe "A buyer purchasing from a cart" do

  def setup
    @sally = users(:sally)
    @sally_billing = @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally_shipping = @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)

    @sam = users(:sam)
    @sam_billing = @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping = @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)

    @products = [products(:widget), products(:knob)]
    @order = @sam.purchase_from @sally, @products
    
    @cart = MerchantSidekick::ShoppingCart::Cart.new
  end

  it "should add line items for a shopping cart" do
    transaction do
      @cart.add(@products)
      @cart.total.to_s.should == "33.94"
      order = @sam.purchase @cart
      order.total.to_s.should == "33.94"
    end
  end

  it "should add multiple shopping carts" do
    transaction do
      cart1 = MerchantSidekick::ShoppingCart::Cart.new
      cart2 = MerchantSidekick::ShoppingCart::Cart.new
      
      cart1.add @products.first
      cart2.add @products.last
      order = @sam.purchase cart1, cart2
      order.total.to_s.should == "33.94"
    end
  end

end

describe "A buyer purchasing a non-sellable model" do

  def setup
    @user = users(:sam)
    @billing = @user.create_billing_address(addresses(:sam_billing).content_attributes)
    @shipping = @user.create_shipping_address(addresses(:sam_shipping).content_attributes)
  end

  it "should raise an error" do
    transaction do
      lambda { @user.purchase @user }.should raise_error(ArgumentError)
    end
  end

end