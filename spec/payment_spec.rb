require File.dirname(__FILE__) + '/../spec_helper'

describe "A payment" do
  
  it "should belong to a payable" do
    lambda { Payment.new.payable(true) }.should_not raise_error
  end
  
  it "should have an amount" do
    Payment.new.should respond_to(:amount)
  end
  
end

