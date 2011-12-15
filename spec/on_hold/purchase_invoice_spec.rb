require File.dirname(__FILE__) + '/../spec_helper'

describe PurchaseInvoice do
  fixtures :addresses, :product_dummies, :user_dummies

  before(:each) do
    # invoice
    @invoice = PurchaseInvoice.new(
      :net_amount => Money.new(2995, 'USD'),
      :tax_rate => 0, # obsolete
      :tax_amount => Money.new(0, 'USD'),
      :gross_amount => Money.new(2995, 'USD'),
      :buyer => user_dummies(:sam),
      :seller => user_dummies(:sally)
    )
    @invoice.should_not be_nil

    # addresses
    @invoice.build_origin_address(addresses(:sally_billing).content_attributes)
    @invoice.build_billing_address(addresses(:sam_billing).content_attributes)
    @invoice.build_shipping_address(addresses(:sam_shipping).content_attributes)

    # line items and add
    @line_item = LineItem.new(
      :order => nil,
      :invoice => @invoice,
      :sellable => product_dummies(:widget),
      :tax_rate => 0
    )
    @line_item.should_not be_nil
    @invoice.line_items.push(@line_item)
    
    # credit card
    @credit_card = valid_credit_card
  end
  
  it "should authorize" do
    payment = nil
    lambda { payment = @invoice.authorize(@credit_card) }.should change(Payment, :count).by(1)
    payment.should be_success
    payment.position.should == 1
    @invoice.current_state.should == :authorized
  end

  it "should capture the payment" do
    authorization_payment = @invoice.authorize(@credit_card)
    authorization_payment.should be_success
    capture_payment = nil
    lambda { capture_payment = @invoice.capture }.should change(Payment, :count).by(1)
    capture_payment.should be_success
  end
  
  it "should not capture without authorization" do
    capture_payment = @invoice.capture
    capture_payment.should be_nil
    @invoice.should be_pending
  end
  
  it "should purchase" do
    payment = nil
    lambda { payment = @invoice.purchase(@credit_card) }.should change(Payment, :count).by(1)
    payment.should be_success
    @invoice.should be_paid
  end
  
  it "should void an authorized payment"
    # bogus gateway does not void, refactor into remote
  
  it "should refund with credit payment"
    # bogus gateway does not void, refactor into remote
  
  
end
