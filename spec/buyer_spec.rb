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
  fixtures :user_dummies, :product_dummies, :addresses
  
  before(:each) do
    @user = user_dummies(:sam)
    @user.create_billing_address(addresses(:sam_billing).content_attributes)
    @user.create_shipping_address(addresses(:sam_shipping).content_attributes)
    
    @product = product_dummies(:widget)
  end
  
  it "should create a new order" do
    lambda do
      order_count = Order.count
      order = @user.purchase @product
      order.should be_an_instance_of(PurchaseOrder)
      order.should be_valid
      order.save!
    end.should change(Order, :count)
  end
  
  it "should add to buyers's orders" do
    order = @user.purchase(@product)
    order.save!
    @user.orders.last.should == order
    order.buyer.should == @user
  end
  
  it "should create line items" do
    order = @user.purchase(@product)
    order.line_items.size.should == 1
    order.line_items.first.sellable.should == @product
  end
  
  it "should set line item amount to sellable price" do
    order = @user.purchase @product
    order.line_items.first.amount.should == @product.price
  end
  
  it "should set line item amount to 0 if sellable does not have a price" do
    @product.price = 0
    order = @user.purchase @product
    order.line_items.first.amount.should == 0.to_money
  end
  
end

describe "A billable purchasing multiple sellables" do
  fixtures :user_dummies, :product_dummies, :addresses
  
  before(:each) do
    @sally = user_dummies(:sally)
    @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)

    @sam = user_dummies(:sam)
    @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
    
    @products = [product_dummies(:widget), product_dummies(:knob)]
    @order = @sam.purchase_from(@sally, @products)
  end
  
  it "should create line items for each sellable" do
    lambda { @order.save! }.should change(LineItem, :count).by(2)
    @order.should have(2).line_items
    @order.line_items.collect(&:sellable).should == @products
  end
end

describe "A billable purchasing a non-sellable model" do
  fixtures :user_dummies, :product_dummies, :addresses
  
  before(:each) do
    @user = user_dummies(:sam)
    @user.create_billing_address(addresses(:sam_billing).content_attributes)
    @user.create_shipping_address(addresses(:sam_shipping).content_attributes)
  end
  
  it "should raise an error" do
    lambda { @user.purchase @user }.should raise_error(ArgumentError)
  end
end