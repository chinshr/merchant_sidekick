require File.dirname(__FILE__) + '/../spec_helper'

describe SalesOrder, "with valid account" do
  fixtures :addresses, :orders, :user_dummies, :product_dummies
  
  before(:each) do
    @sam = user_dummies(:sam)
    # workaround as fixtures do not load addresses correctly
    @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam.billing_address.to_s.should_not be_blank
    @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
    @sam.shipping_address.to_s.should_not be_blank
    
    @user = @sally = user_dummies(:sally)
    # workaround as fixtures do not load addresses correctly
    @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally.billing_address.to_s.should_not be_blank
    @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)
    @sally.shipping_address.to_s.should_not be_blank
    
    @product = product_dummies(:widget)
    @order = @sally.sell_to @sam, @product
    @account = "pass@test.tst"
    
    ActiveMerchant::Billing::Base.mode = :test
    CreditCardPayment.gateway = ActiveMerchant::Billing::BogusGateway.new
  end

  it "should return a payment" do
    @order.cash(@account).should be_instance_of(CreditCardPayment)
  end
  
  it "should return success" do
    @order.cash(@account).should be_success
  end

  it "should be set to state pending" do
    @order.cash(@account)
    @order.should be_approved
  end

  it "should have a valid invoice" do
    @order.cash(@account)
    @order.invoice.should_not be_nil
    @order.invoice_id.should_not be_nil
    @order.invoice.should be_instance_of(SalesInvoice)
    @order.invoice.should be_paid
  end
  
  it "should set payment amount equal to order amount" do
    @order.cash(@account).amount.should == @order.total
  end

  it "should have corret addresses" do
    @order.origin_address.to_s.should_not be_blank
    @order.origin_address.to_s.should == @sally.billing_address.to_s

    @order.billing_address.to_s.should_not be_blank
    @order.billing_address.to_s.should == @sam.billing_address.to_s

    @order.shipping_address.to_s.should_not be_blank
    @order.shipping_address.to_s.should == @sam.shipping_address.to_s

    @order.cash(@account).should be_success

    @order.invoice.origin_address.to_s.should_not be_blank
    @order.invoice.origin_address.to_s.should == @sally.billing_address.to_s

    @order.invoice.billing_address.to_s.should_not be_blank
    @order.invoice.billing_address.to_s.should == @sam.billing_address.to_s

    @order.invoice.shipping_address.to_s.should_not be_blank
    @order.invoice.shipping_address.to_s.should == @sam.shipping_address.to_s
  end

  describe SalesOrder, "with invalid account" do
    fixtures :user_dummies, :product_dummies

    before(:each) do
      @sam = user_dummies(:sam)
      # workaround as fixtures do not load addresses correctly
      @sam.create_billing_address(addresses(:sam_billing).content_attributes)
      @sam.billing_address.to_s.should_not be_blank
      @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
      @sam.shipping_address.to_s.should_not be_blank

      @user = @sally = user_dummies(:sally)
      # workaround as fixtures do not load addresses correctly
      @sally.create_billing_address(addresses(:sally_billing).content_attributes)
      @sally.billing_address.to_s.should_not be_blank
      @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)
      @sally.shipping_address.to_s.should_not be_blank

      @order = @sally.sell_to @sam, product_dummies(:widget)
      @payment = @order.cash 'error@error.tst'
    end

    it "should initialize and save the order and invoice" do
      @order.should be_is_a(SalesOrder)
      @order.should_not be_new_record
      @order.invoice.should be_payment_declined
      @order.should be_created
    end

  end

end
