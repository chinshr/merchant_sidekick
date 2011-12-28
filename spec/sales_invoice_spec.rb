require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::SalesInvoice do

  def setup
    @buyer          = users(:sam)
    @seller         = users(:sally)
    @product        = products(:widget)
    @invoice        = MerchantSidekick::SalesInvoice.new(
      :net_amount   => Money.new(2995, 'USD'),
      :tax_amount   => Money.new(0, 'USD'),
      :gross_amount => Money.new(2995, 'USD'),
      :buyer        => @buyer,
      :seller       => @seller
    )

    # addresses
    @sally_billing = @invoice.build_origin_address(addresses(:sally_billing).content_attributes)
    @sam_billing   = @invoice.build_billing_address(addresses(:sam_billing).content_attributes)
    @sam_shipping  = @invoice.build_shipping_address(addresses(:sam_shipping).content_attributes)

    # line items and add
    @line_item = MerchantSidekick::LineItem.new(
      :order => nil,
      :invoice => @invoice,
      :sellable => @product,
      :tax_rate => 0
    )
    @line_item.should_not be_nil
    @invoice.line_items.push(@line_item)

    # credit card
    @credit_card = valid_credit_card
  end

  it "should cash" do
    transaction do
      lambda {
        payment = @invoice.cash("success@test.tst")
        payment.should be_success
        payment.position.should == 1
        @invoice.current_state.should == :paid
      }.should change(MerchantSidekick::Payment, :count).by(1)
    end
  end

  it "should not cash" do
    transaction do
      lambda {
        payment = @invoice.cash("error@error.tst")
        payment.should_not be_success
        payment.position.should == 1
        @invoice.current_state.should == :payment_declined
      }.should change(MerchantSidekick::Payment, :count).by(1)
    end
  end

end
