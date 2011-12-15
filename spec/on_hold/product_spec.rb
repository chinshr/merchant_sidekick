require File.dirname(__FILE__) + '/../spec_helper'

describe "A sellable" do

  it "should have a price" do
    lambda { ProductDummy.new.price }.should_not raise_error
  end
  
  it "should have many line_items" do
    lambda { ProductDummy.new.line_items(true) }.should_not raise_error
  end
  
  it "should have many orders" do
    lambda { ProductDummy.new.orders(true) }.should_not raise_error
  end
  
end