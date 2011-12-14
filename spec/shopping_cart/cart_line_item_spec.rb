require File.dirname(__FILE__) + '/../spec_helper'

class ProductWithNameAndSku < ProductDummy
  def name
    "A beautiful name"
  end
  
  def sku
    "PR1234"
  end
  
  def description 
    "Wonderful name!"
  end
  
  def taxable
    true
  end
  
end

class ProductWithTitleAndNumber < ProductDummy
  def title
    "A beautiful title"
  end
  
  def number
    "PR1234"
  end
  
  def description 
    "Wonderful title!"
  end

  def new_record?
    true
  end
end

class ProductWithCopy < ProductDummy
  
  def copy_name(options={})
    "customized name"
  end
  
  def copy_item_number(options={})
    "customized item number"
  end

  def copy_description(options={})
    "customized description"
  end
  
  def copy_price(options={})
    Money.new(9999, 'USD')
  end
  
end

def valid_cart_line_item_attributes(attrs={})
  {
    :quantity => 5
  }.merge(attrs)
end

describe MerchantSidekick::ShoppingCart::LineItem do
  fixtures :product_dummies

  before(:each) do
    @product = product_dummies(:widget)
  end

  it "should initialize and create" do
    item = MerchantSidekick::ShoppingCart::LineItem.new(valid_cart_line_item_attributes(:product => @product))
    item.should be_valid
    item.save!
    item.product.should == @product
    item.item_number.should == @product.id  # as there is no sku, or number field in product
    item.name.should == @product.title
    item.description.should be_nil  # as there is not description field
    item.quantity.should == 5
    item.unit.should == :piece
    item.pieces.should == 1
    item.total_price.to_s.should == '149.75'
    item.should be_taxable
  end

  it "should copy name and sku" do
    product = ProductWithNameAndSku.new(:price => Money.new(999, "USD"))
    item = MerchantSidekick::ShoppingCart::LineItem.new(valid_cart_line_item_attributes(:product => product))
#    item.name.should == "A beautiful name"
    item.item_number.should == "PR1234"
    item.description.should == "Wonderful name!"
  end

  it "should copy title and number" do
    product = ProductWithTitleAndNumber.new(:price => Money.new(999, "USD"))
    item = MerchantSidekick::ShoppingCart::LineItem.new(valid_cart_line_item_attributes(:product => product))
    item.name.should == "A beautiful title"
    item.item_number.should == "PR1234"
    item.description.should == "Wonderful title!"
  end

  it "should copy from copy methods" do
    product = ProductWithCopy.new(:price => Money.new(99, "USD"))
    item = MerchantSidekick::ShoppingCart::LineItem.new(valid_cart_line_item_attributes(:product => product))
    item.name.should == "customized name"
    item.item_number.should == "customized item number"
    item.description.should == "customized description"
    item.unit_price.to_s.should == "99.99"
    item.total_price.to_s.should == "499.95"
  end


end
