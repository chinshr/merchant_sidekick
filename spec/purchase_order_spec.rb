require File.expand_path("../spec_helper", __FILE__)

describe "authorize with an invalid credit card will not save the order" do

  def setup
    @user         = users(:sam)
    @product      = products(:widget)
    @sam_billing  = @user.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping = @user.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @order        = @user.purchase @product
    @payment      = @order.authorize invalid_credit_card
  end

  it "should initialize but not save the order" do
    transaction do
      @order.should be_new_record
    end
  end

  it "should initialize but not save a payment" do
    transaction do
      @payment.should be_new_record
    end
  end

end

describe "authorize with a valid credit card" do

  def setup
    @user         = users(:sam)
    @sam_billing  = @user.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping = @user.create_shipping_address(addresses(:sam_shipping).content_attributes)

    @product      = products(:widget)
    @order        = @user.purchase @product
    @credit_card  = valid_credit_card
  end

  it "should return a payment" do
    transaction do
      @user.should_receive(:before_authorize_payment)
      @user.should_receive(:after_authorize_payment)
      @order.should_receive(:enter_pending)
      @order.authorize(@credit_card).should be_instance_of(MerchantSidekick::ActiveMerchant::CreditCardPayment)
    end
  end

  it "should return success" do
    transaction do
      @order.should_receive(:enter_pending)
      @order.authorize(@credit_card).should be_success
    end
  end

  it "should be set to state pending" do
    transaction do
      @order.authorize(@credit_card)
      @order.should be_pending
    end
  end

  it "should have a valid invoice" do
    transaction do
      @order.authorize(@credit_card)
      @order.invoices.should_not be_empty
      @order.invoices.first.id.should_not be_nil
      @order.invoices.first.should be_instance_of(MerchantSidekick::PurchaseInvoice)
      @order.invoices.first.should be_authorized
    end
  end

  it "should set payment amount equal to order amount" do
    transaction do
      @order.authorize(@credit_card).amount.should == @order.total
    end
  end

  it "should set payment authorization reference number" do
    transaction do
      @order.authorize(@credit_card).reference.should_not be_nil
    end
  end

end

describe "Deleting an order" do
  def setup
    @widget    = products(:widget)
    @knob      = products(:knob)
    @li_widget = line_items(:sams_widget)
    @li_knob   = line_items(:sams_knob)
    @order     = orders(:sams_widget)
    @order.reload
  end
  
  it "should delete associated line items" do
    transaction do
      @order.line_items.count.should == 2
      @order.destroy
      @order.line_items.count.should == 0
    end
  end
end

describe "Cancelling an order" do
  def setup
    @widget    = products(:widget)
    @knob      = products(:knob)
    @li_widget = line_items(:sams_widget)
    @li_knob   = line_items(:sams_knob)
    @order     = orders(:sams_widget)
    @order.reload
  end
  
  it "should record that order was cancelled" do
    transaction do
      @order.canceled_at.should be_nil
      @order.current_state.should == :created
      @order.cancel!
      @order.current_state.should == :canceled
    end
  end
end

describe "Paying an order with valid credit card" do
  def setup
    @buyer        = users(:sam)
    @sam_billing  = @buyer.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping = @buyer.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @order        = orders(:unpaid)
    @credit_card  = ActiveMerchant::Billing::CreditCard.new valid_credit_card_attributes(:number => "1")
    @order.reload
    mock_gateway(false, @order, @credit_card)
  end

  it "should return an unsuccessful payment" do
    transaction do
      @order.buyer.should_receive(:before_payment)
      @order.buyer.should_receive(:after_payment)
      @order.should_receive(:enter_pending)
#      @order.should_receive(:exit_pending)
      @order.should_receive(:enter_approved)
#      @order.should_receive(:exit_approved)
      payment = @order.pay(@credit_card)
      payment.action.should == "purchase"
      payment.success.should == true
      payment.should_not be_new_record
      @order.current_state.should == :approved
    end
  end
end

describe "Paying an order with an invalid credit card" do
  def setup
    @buyer        = users(:sam)
    @sam_billing  = @buyer.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping = @buyer.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @order        = orders(:unpaid)
    @credit_card  = ActiveMerchant::Billing::CreditCard.new valid_credit_card_attributes(:number => "2")
    @order.reload
    mock_gateway(false, @order, @credit_card)
  end

  it "should return an unsuccessful payment" do
    transaction do
      @order.buyer.should_receive(:before_payment)
      @order.buyer.should_receive(:after_payment)
      payment = @order.pay(@credit_card)
      payment.action.should == "purchase"
      payment.success.should == false
      payment.should_not be_new_record
    end
  end
end

def mock_gateway(success, order, credit_card, options = {})
  @gateway = mock("gateway")
  @response = mock("response")
  @response.stub!(:success?).and_return(success)
  if success
    @response.should_receive(:authorization).and_return("12345")
  else
    @response.stub!(:message).and_return("Invalid credit card number")
  end

  @gateway.stub!(:purchase).with(order.gross_total, credit_card, {
    :buyer => order.buyer}.merge(options)).and_return(@response)

  ActiveMerchant::Billing::Base.stub!(:default_gateway).and_return(@gateway)
end
