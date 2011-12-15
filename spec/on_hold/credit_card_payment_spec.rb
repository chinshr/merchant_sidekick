require File.dirname(__FILE__) + '/../spec_helper'

describe CreditCardPayment, "authorization" do
  
  before(:each) do
    @amount = Money.new(100, 'USD')
  end
  
  it "should succeed" do
    auth = CreditCardPayment.authorize(
      @amount,
      credit_card(valid_credit_card_attributes)
    )
    auth.success.should == true
    auth.action.should == 'authorization'
    auth.message.should == BogusGateway::SUCCESS_MESSAGE
    auth[:reference].should == BogusGateway::AUTHORIZATION
  end
  
  it "should fail" do
    auth = CreditCardPayment.authorize(
      @amount,
      credit_card(invalid_credit_card_attributes)
    )
    auth.success.should == false
    auth.action.should == 'authorization'
    auth.message.should == BogusGateway::FAILURE_MESSAGE
  end
  
  it "should error" do
    auth = CreditCardPayment.authorize(
      @amount,
      credit_card(valid_credit_card_attributes(:number => '3'))
    )
    auth.success.should == false
    auth.action.should == 'authorization'
    auth.message.should == BogusGateway::ERROR_MESSAGE
  end
  
end

describe CreditCardPayment, "capture" do
  
  before(:each) do
    @amount = Money.new(100, 'USD')
  end
  
  it "should capture successfully" do
    capt = CreditCardPayment.capture(
      @amount,
      '123'
    )
    capt.success.should == true
    capt.action.should == 'capture'
    capt.message.should == BogusGateway::SUCCESS_MESSAGE
  end
  
  it "should fail capture" do
    capt = CreditCardPayment.capture(
      @amount,
      '2'
    )
    capt.success.should == false
    capt.action.should == 'capture'
    capt.message.should == BogusGateway::FAILURE_MESSAGE
  end
  
  it "should error capture" do
    capt = CreditCardPayment.capture(
      @amount,
      '1'
    )
    capt.success.should == false
    capt.action.should == 'capture'
    capt.message.should == BogusGateway::CAPTURE_ERROR_MESSAGE
  end
  
end

describe CreditCardPayment, "transfer method" do
  
  before(:each) do
    @amount = Money.new(100, 'USD')
  end
  
  it "should sucessfully transfer" do
    capt = CreditCardPayment.transfer(
      @amount,
      'account@test.tst'
    )
    capt.success.should == true
    capt.action.should == 'transfer'
    capt.message.should == BogusGateway::SUCCESS_MESSAGE
  end

  it "should return error" do
    capt = CreditCardPayment.transfer(
      @amount,
      'error@error.tst'
    )
    capt.success.should == false
    capt.action.should == 'transfer'
    capt.message.should == BogusGateway::ERROR_MESSAGE
  end

  it "should fail" do
    capt = CreditCardPayment.transfer(
      @amount,
      'fail@error.tst'
    )
    capt.success.should == false
    capt.action.should == 'transfer'
    capt.message.should == BogusGateway::FAILURE_MESSAGE
  end
  
end

