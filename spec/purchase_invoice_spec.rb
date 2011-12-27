require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::PurchaseInvoice do

  def setup
    @buyer   = users(:sam)
    @seller  = users(:sally)
    @product = products(:widget)
    @invoice = MerchantSidekick::PurchaseInvoice.new(
      :net_amount => Money.new(2995, 'USD'),
      :gross_amount => Money.new(2995, 'USD'),
      :buyer => @buyer,
      :seller => @seller
    )

    @sally_billing = @invoice.build_origin_address(addresses(:sally_billing).content_attributes)
    @sam_billing   = @invoice.build_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping  = @invoice.build_shipping_address(addresses(:sam_shipping).content_attributes)

    @line_item = MerchantSidekick::LineItem.new(
      :order => nil,
      :invoice => @invoice,
      :sellable => @product
    )
    @invoice.line_items.push(@line_item)
    
    @credit_card = valid_credit_card
  end
  
  it "should authorize" do
    transaction do
      lambda { 
        payment = @invoice.authorize(@credit_card) 
        payment.should be_success
        payment.position.should == 1
        @invoice.current_state.should == :authorized
      }.should change(MerchantSidekick::Payments::Payment, :count).by(1)
    end
  end

  it "should capture the payment" do
    transaction do
      authorization_payment = @invoice.authorize(@credit_card)
      authorization_payment.should be_success
      lambda { 
        capture_payment = @invoice.capture 
        capture_payment.should be_success
      }.should change(MerchantSidekick::Payments::Payment, :count).by(1)
    end
  end
  
  it "should not capture without authorization" do
    transaction do
      payment = @invoice.capture
      payment.should be_nil
      @invoice.should be_pending
    end
  end
  
  it "should purchase" do
    transaction do
      lambda { 
        payment = @invoice.purchase(@credit_card) 
        payment.should be_success
        @invoice.should be_paid
      }.should change(MerchantSidekick::Payments::Payment, :count).by(1)
    end
  end
  
=begin
  it "should void an authorized payment"
    # bogus gateway does not void, refactor into remote
  
  it "should refund with credit payment"
    # bogus gateway does not void, refactor into remote
=end
  
end