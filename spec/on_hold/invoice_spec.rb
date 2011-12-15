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
  
  it "should be a valid invoice instance" do
    # money
    @invoice.net_total.to_s.should == '29.95'
    @invoice.tax_total.to_s.should == '0.00'
    @invoice.gross_total.to_s.should == '29.95'
    
    # actors
    @invoice.seller.should == user_dummies(:sally)
    @invoice.buyer.should == user_dummies(:sam)
    
    # line item
    @invoice.line_items.size.should == 1
    @invoice.line_items[0].invoice.should be_is_a(PurchaseInvoice)
    @invoice.line_items[0].invoice.should == @invoice

    # addresses
    @invoice.origin_address.to_s.should == addresses(:sally_billing).to_s
    @invoice.origin_address.should be_is_a(OriginAddress)
    @invoice.origin_address.addressable.should == @invoice

    @invoice.billing_address.to_s.should == addresses(:sam_billing).to_s
    @invoice.billing_address.should be_is_a(BillingAddress)
    @invoice.billing_address.addressable.should == @invoice

    @invoice.shipping_address.to_s.should == addresses(:sam_shipping).to_s
    @invoice.shipping_address.should be_is_a(ShippingAddress)
    @invoice.shipping_address.addressable.should == @invoice
  end

  it "should save addresses" do
    lambda { @invoice.save }.should change(Address, :count).by(3)
    @invoice = Invoice.find_by_id(@invoice.id)
    @invoice.origin_address.to_s.should == addresses(:sally_billing).to_s
    @invoice.billing_address.to_s.should == addresses(:sam_billing).to_s
    @invoice.shipping_address.to_s.should == addresses(:sam_shipping).to_s
  end

  it "should save line items" do
    lambda { @invoice.save }.should change(LineItem, :count).by(1)
    @invoice = Invoice.find_by_id(@invoice.id)
    @invoice.line_items[0].should == @line_item
  end
  
end
