require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::SalesOrder, "with valid account" do
  
  def setup
    @sam = users(:sam)
    @sam_billing = @sam.create_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping = @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)
    
    @user = @sally = users(:sally)
    @sally_billing = @sally.create_billing_address(addresses(:sally_billing).content_attributes)
    @sally_shipping = @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)
    
    @product = products(:widget)
    @order = @sally.sell_to @sam, @product
    @account = "pass@test.tst"
    
    # ActiveMerchant::Billing::Base.mode = :test
  end

  it "should return a payment" do
    transaction do
      @order.cash(@account).should be_instance_of(MerchantSidekick::ActiveMerchant::CreditCardPayment)
    end
  end
  
  it "should return success" do
    transaction do
      @order.cash(@account).should be_success
    end
  end

  it "should be set to state pending" do
    transaction do
      @order.cash(@account)
      @order.should be_approved
    end
  end

  it "should have a valid invoice" do
    transaction do
      @order.cash(@account)
      @order.invoice.should_not be_nil
      @order.invoice_id.should_not be_nil
      @order.invoice.should be_instance_of(MerchantSidekick::SalesInvoice)
      @order.invoice.should be_paid
    end
  end
  
  it "should set payment amount equal to order amount" do
    transaction do
      @order.cash(@account).amount.should == @order.total
    end
  end

  it "should have corret addresses" do
    transaction do
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
  end

  describe MerchantSidekick::SalesOrder, "with invalid account" do

    def setup
      @sam            = users(:sam)
      @product        = products(:widget)
      @sam_billing    = @sam.create_billing_address(addresses(:sam_billing).content_attributes)
      @sam_shipping   = @sam.create_shipping_address(addresses(:sam_shipping).content_attributes)

      @user           = @sally = users(:sally)
      @sally_billing  = @sally.create_billing_address(addresses(:sally_billing).content_attributes)
      @sally_shipping = @sally.create_shipping_address(addresses(:sally_shipping).content_attributes)

      @order          = @sally.sell_to @sam, @product
      @payment        = @order.cash 'error@error.tst'
    end

    it "should initialize and save the order and invoice" do
      transaction do
        @order.should be_is_a(MerchantSidekick::SalesOrder)
        @order.should_not be_new_record
        @order.invoice.should be_payment_declined
        @order.should be_created
      end
    end

  end

end
