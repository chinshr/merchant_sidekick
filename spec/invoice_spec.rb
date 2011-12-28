require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::Invoice do

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
      :order    => nil,
      :invoice  => @invoice,
      :sellable => @product
    )
    @invoice.line_items.push(@line_item)

    @credit_card = valid_credit_card
  end

  it "should be a valid invoice instance" do
    transaction do
      # money
      @invoice.net_total.should   == '29.95'.to_money
      @invoice.tax_total.should   == '0.00'.to_money
      @invoice.gross_total.should == '29.95'.to_money

      # actors
      @invoice.seller.should == @seller
      @invoice.buyer.should  == @buyer

      # line item
      @invoice.line_items.size.should == 1
      @invoice.line_items[0].invoice.should be_is_a(MerchantSidekick::PurchaseInvoice)
      @invoice.line_items[0].invoice.should == @invoice

      # addresses
      @invoice.origin_address.to_s.should == @sally_billing.to_s
      @invoice.origin_address.should be_is_a(OriginAddress)
      @invoice.origin_address.addressable.should == @invoice

      @invoice.billing_address.to_s.should == @sam_billing.to_s
      @invoice.billing_address.should be_is_a(BillingAddress)
      @invoice.billing_address.addressable.should == @invoice

      @invoice.shipping_address.to_s.should == @sam_shipping.to_s
      @invoice.shipping_address.should be_is_a(ShippingAddress)
      @invoice.shipping_address.addressable.should == @invoice
    end
  end

  it "should save addresses" do
    transaction do
      lambda { @invoice.save }.should change(MerchantSidekick::Addressable::Address, :count).by(3)
      @invoice = MerchantSidekick::Invoice.find_by_id(@invoice.id)
      @invoice.origin_address.to_s.should == addresses(:sally_billing).to_s
      @invoice.billing_address.to_s.should == addresses(:sam_billing).to_s
      @invoice.shipping_address.to_s.should == addresses(:sam_shipping).to_s
    end
  end

  it "should save line items" do
    transaction do
      lambda { @invoice.save }.should change(MerchantSidekick::LineItem, :count).by(1)
      @invoice = MerchantSidekick::Invoice.find_by_id(@invoice.id)
      @invoice.line_items[0].should == @line_item
    end
  end

end
