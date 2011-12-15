require File.dirname(__FILE__) + '/../spec_helper'

describe "authorize with an invalid credit card will not save the order" do
  fixtures :user_dummies, :product_dummies, :addresses
  
  before(:each) do
    @user = user_dummies(:sam)
    @user.create_billing_address(addresses(:sam_billing).content_attributes)
    @user.create_shipping_address(addresses(:sam_shipping).content_attributes)
    
    @order = @user.purchase product_dummies(:widget)
    @payment = @order.authorize invalid_credit_card
  end
  
  it "should initialize but not save the order" do
    @order.should be_new_record
  end
  
  it "should initialize but not save a payment" do
    @payment.should be_new_record
  end
  
end

describe "authorize with a valid credit card" do
  fixtures :orders, :user_dummies, :product_dummies, :addresses
  
  before(:each) do
    @user = user_dummies(:sam)
    @user.create_billing_address(addresses(:sam_billing).content_attributes)
    @user.create_shipping_address(addresses(:sam_shipping).content_attributes)
    
    @product = product_dummies(:widget)
    @order = @user.purchase @product
    @credit_card = valid_credit_card
    
    ActiveMerchant::Billing::Base.mode = :test
    CreditCardPayment.gateway = ActiveMerchant::Billing::BogusGateway.new
  end

  it "should return a payment" do
    @order.authorize(@credit_card).should be_instance_of(CreditCardPayment)
  end
  
  it "should return success" do
    @order.authorize(@credit_card).should be_success
  end

  it "should be set to state pending" do
    @order.authorize(@credit_card)
    @order.should be_pending
  end

  it "should have a valid invoice" do
    @order.authorize(@credit_card)
    @order.invoice.should_not be_nil
    @order.invoice_id.should_not be_nil
    @order.invoice.should be_instance_of(PurchaseInvoice)
    @order.invoice.should be_authorized
  end
  
  it "should set payment amount equal to order amount" do
    @order.authorize(@credit_card).amount.should == @order.total
  end

  it "should set payment authorization reference number" do
    @order.authorize(@credit_card).reference.should_not be_nil
  end
  
end

=begin
describe "Deleting an order" do
  fixtures :orders, :line_items

  it "should delete associated line items" do
    orders(:sams_widget).destroy
    lambda { LineItem.find(line_items(:sams_widget).id) }.should raise_error(ActiveRecord::RecordNotFound)
  end
end

describe "Canceling an order" do
  fixtures :orders, :line_items
  
  before(:each) do
    @order = orders(:sams_widget)
  end
  
  it "should record the date the order was canceled" do
    @order.canceled_at.should be_nil
    @order.cancel!
    @order.canceled_at.should_not be_nil
  end
end

describe "Paying an order with an invalid credit card" do
  fixtures :orders
  
  before(:each) do
    @order = orders(:unpaid)
    @credit_card = ActiveMerchant::Billing::CreditCard.new valid_credit_card_attrs(:number => "2")
    mock_gateway(false, @order, @credit_card)
  end

  it "should raise AuthorizationError" do
    lambda { @order.pay(@credit_card) }.should raise_error(Payment::AuthorizationError)
  end
end

describe "Paying an order with additional options" do
  fixtures :orders
  
  before(:each) do
    @order = orders(:unpaid)
    @credit_card = mock("credit card")
    @credit_card.stub!(:number).and_return("1")
  end
  
  it "should pass options to gateway" do
    @options = { :ip => '10.0.0.1' }
    mock_gateway(true, @order, @credit_card, @options)
    @order.pay(@credit_card, @options).amount.should == @order.amount
  end
end

describe "Paying an order with a billing address" do
  fixtures :orders
  
  before(:each) do
    @order = orders(:unpaid)
    @credit_card = mock("credit card")
    @credit_card.stub!(:number).and_return("1")
    @address = Address.new(
      :name => "Test Person",
      :street1 => "123 ABC Street",
      :locality => "Somewhere",
      :region => "NA",
      :postal_code => "12345",
      :country => "USA"
    )
    mock_gateway(true, @order, @credit_card, :billing_address => @address)
  end
  
  it "should save address" do
    lambda { @order.pay(@credit_card, :billing_address => @address) }.should change(Address, :count).by(1)
  end
  
end

describe "Authorizing a payment" do
  fixtures :orders
  
  before(:each) do
    @order = orders(:unpaid)
    @credit_card = mock("credit card")
    @credit_card.stub!(:number).and_return("1")
    mock_gateway_authorization(true, @order, @credit_card)
  end
  
  def authorize
    @order.authorize(@credit_card)
  end
  
  it "should return a payment" do
    authorize.should be_instance_of(Payment)
  end
  
  it "should set authorization number" do
    authorize.confirmation.should_not be_nil
  end
  
end

def mock_gateway_authorization(success, order, credit_card, options ={})
  @response = mock("response")
  @response.should_receive(:success?).and_return(success)
  if success
    @response.should_receive(:authorization).and_return("12345")
  else
    @response.should_receive(:message).and_return("Invalid credit card number")
  end
  
  @gateway = mock("gateway")
  @gateway.should_receive(:authorize).with(order.amount, credit_card,
    {:order_id => order.id, :customer => order.billable_id}.merge(options)).and_return(@response)
  ActiveMerchant::Billing::Base.stub!(:default_gateway).and_return(@gateway)
end

def mock_gateway(success, order, credit_card, options = {})
  @gateway = mock("gateway")
  @response = mock("response")
  @response.should_receive(:success?).and_return(success)
  if success
    @response.should_receive(:authorization).and_return("12345")
  else
    @response.should_receive(:message).and_return("Invalid credit card number")
  end

  @gateway.should_receive(:purchase).with(order.amount, credit_card, {:order_id => order.id,
    :customer => order.billable_id}.merge(options)).and_return(@response)
  
  ActiveMerchant::Billing::Base.stub!(:default_gateway).and_return(@gateway)
end
=end