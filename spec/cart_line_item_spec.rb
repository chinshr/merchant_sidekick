require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::ShoppingCart::LineItem do

  def setup
    @product = products(:widget)
  end

  it "should initialize and create" do
    transaction do
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
  end

  it "should copy name and sku" do
    transaction do
      product = ProductWithNameAndSku.new(:price => Money.new(999, "USD"))
      item = MerchantSidekick::ShoppingCart::LineItem.new(valid_cart_line_item_attributes(:product => product))
      # item.name.should == "A beautiful name" # TODO fix attribute priority
      item.item_number.should == "PR1234"
      item.description.should == "Wonderful name!"
    end
  end

  it "should copy title and number" do
    transaction do
      product = ProductWithTitleAndNumber.new(:price => Money.new(999, "USD"))
      item = MerchantSidekick::ShoppingCart::LineItem.new(valid_cart_line_item_attributes(:product => product))
      item.name.should == "A beautiful title"
      item.item_number.should == "PR1234"
      item.description.should == "Wonderful title!"
    end
  end

  it "should duplicate from copy methods" do
    transaction do
      product = ProductWithCopy.new(:price => Money.new(99, "USD"))
      item = MerchantSidekick::ShoppingCart::LineItem.new(valid_cart_line_item_attributes(:product => product))
      item.name.should == "customized name"
      item.item_number.should == "customized item number"
      item.description.should == "customized description"
      item.unit_price.to_s.should == "99.99"
      item.total_price.to_s.should == "499.95"
    end
  end

end
