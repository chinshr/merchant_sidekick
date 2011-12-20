require File.expand_path("../spec_helper", __FILE__)

describe "A sellable" do

  it "should have a price" do
    lambda { Product.new.price }.should_not raise_error
  end
  
  it "should have many line_items" do
    lambda { Product.new.line_items(true) }.should_not raise_error
  end
  
  it "should have many orders" do
    lambda { Product.new.orders(true) }.should_not raise_error
  end
  
end