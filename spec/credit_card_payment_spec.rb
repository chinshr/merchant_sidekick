require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::ActiveMerchant::CreditCardPayment, "authorization" do

  def setup
    @amount = Money.new(100, 'USD')
  end

  it "should succeed" do
    transaction do
      auth = MerchantSidekick::ActiveMerchant::CreditCardPayment.authorize(
        @amount,
        credit_card(valid_credit_card_attributes)
      )
      auth.success.should == true
      auth.action.should == 'authorization'
      auth.message.should == ActiveMerchant::Billing::BogusGateway::SUCCESS_MESSAGE
      auth[:reference].should == ActiveMerchant::Billing::BogusGateway::AUTHORIZATION
    end
  end

  it "should fail" do
    transaction do
      auth = MerchantSidekick::ActiveMerchant::CreditCardPayment.authorize(
        @amount,
        credit_card(invalid_credit_card_attributes)
      )
      auth.success.should == false
      auth.action.should == 'authorization'
      auth.message.should == ActiveMerchant::Billing::BogusGateway::FAILURE_MESSAGE
    end
  end

  it "should error" do
    transaction do
      auth = MerchantSidekick::ActiveMerchant::CreditCardPayment.authorize(
        @amount,
        credit_card(valid_credit_card_attributes(:number => '3'))
      )
      auth.success.should == false
      auth.action.should == 'authorization'
      auth.message.should == ActiveMerchant::Billing::BogusGateway::ERROR_MESSAGE
    end
  end

end

describe MerchantSidekick::ActiveMerchant::CreditCardPayment, "capture" do

  def setup
    @amount = Money.new(100, 'USD')
  end

  it "should capture successfully" do
    transaction do
      capt = MerchantSidekick::ActiveMerchant::CreditCardPayment.capture(
        @amount,
        '123'
      )
      capt.success.should == true
      capt.action.should == 'capture'
      capt.message.should == ActiveMerchant::Billing::BogusGateway::SUCCESS_MESSAGE
    end
  end

  it "should fail capture" do
    transaction do
      capt = MerchantSidekick::ActiveMerchant::CreditCardPayment.capture(
        @amount,
        '2'
      )
      capt.success.should == false
      capt.action.should == 'capture'
      capt.message.should == ActiveMerchant::Billing::BogusGateway::FAILURE_MESSAGE
    end
  end

  it "should error capture" do
    transaction do
      capt = MerchantSidekick::ActiveMerchant::CreditCardPayment.capture(
        @amount,
        '1'
      )
      capt.success.should == false
      capt.action.should == 'capture'
      capt.message.should == ActiveMerchant::Billing::BogusGateway::CAPTURE_ERROR_MESSAGE
    end
  end

end

describe MerchantSidekick::ActiveMerchant::CreditCardPayment, "transfer method" do

  def setup
    @amount = Money.new(100, 'USD')
  end

  it "should sucessfully transfer" do
    transaction do
      capt = MerchantSidekick::ActiveMerchant::CreditCardPayment.transfer(
        @amount,
        'account@test.tst'
      )
      capt.success.should == true
      capt.action.should == 'transfer'
      capt.message.should == ActiveMerchant::Billing::BogusGateway::SUCCESS_MESSAGE
    end
  end

  it "should return error" do
    transaction do
      capt = MerchantSidekick::ActiveMerchant::CreditCardPayment.transfer(
        @amount,
        'error@error.tst'
      )
      capt.success.should == false
      capt.action.should == 'transfer'
      capt.message.should == ActiveMerchant::Billing::BogusGateway::ERROR_MESSAGE
    end
  end

  it "should fail" do
    transaction do
      capt = MerchantSidekick::ActiveMerchant::CreditCardPayment.transfer(
        @amount,
        'fail@error.tst'
      )
      capt.success.should == false
      capt.action.should == 'transfer'
      capt.message.should == ActiveMerchant::Billing::BogusGateway::FAILURE_MESSAGE
    end
  end

end