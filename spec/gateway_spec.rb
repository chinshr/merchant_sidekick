require File.expand_path("../spec_helper", __FILE__)

describe MerchantSidekick::Gateway do

  before(:each) do
    MerchantSidekick::Gateway.default_gateway = nil
    MerchantSidekick::Gateway.config          = nil
    MerchantSidekick::Gateway.config_path     = nil
    MerchantSidekick::Gateway.gateway         = nil
  end

  it "should have a config file name" do
    MerchantSidekick::Gateway.should respond_to(:config_file_name)
    MerchantSidekick::Gateway.config_file_name.should == "merchant_sidekick.yml"
  end
  
  it "should have a config path" do
    MerchantSidekick::Gateway.should respond_to(:config_path)
    Pathname.new(MerchantSidekick::Gateway.config_path).basename.to_s.should == "merchant_sidekick.yml"
  end

  it "should have a default gateway" do
    MerchantSidekick::Gateway.should respond_to(:default_gateway)
  end

  it "should have a type" do
    MerchantSidekick::Gateway.should respond_to(:type)
    MerchantSidekick::Gateway.type.should == :gateway
  end

  it "should have a config" do
    MerchantSidekick::Gateway.should respond_to(:config)
  end

  it "should read from default config" do
    MerchantSidekick::Gateway.config.should be_instance_of(Hash)
  end

  after(:all) do
    MerchantSidekick::Gateway.default_gateway = ActiveMerchant::Billing::BogusGateway.new
  end

end


describe MerchantSidekick::ActiveMerchant::Gateways::AuthorizeNetGateway do

  before(:each) do
    MerchantSidekick::Gateway.default_gateway  = nil
    MerchantSidekick::Gateway.config           = nil
    MerchantSidekick::Gateway.config_path      = nil
  end

  it "should read config" do
    MerchantSidekick::ActiveMerchant::Gateways::AuthorizeNetGateway.config[:login_id].should == "foo"
    MerchantSidekick::ActiveMerchant::Gateways::AuthorizeNetGateway.config[:transaction_key].should == "bar"
  end

  it "should return active merchant authorize_net gateway instance" do
    MerchantSidekick::ActiveMerchant::Gateways::AuthorizeNetGateway.gateway.should be_instance_of(::ActiveMerchant::Billing::AuthorizeNetGateway)
  end

  after(:all) do
    MerchantSidekick::Gateway.default_gateway = ActiveMerchant::Billing::BogusGateway.new
  end

end


describe MerchantSidekick::ActiveMerchant::Gateways::PaypalGateway do

  before(:each) do
    MerchantSidekick::Gateway.default_gateway = nil
    MerchantSidekick::Gateway.config          = nil
    MerchantSidekick::Gateway.config_path     = nil
    MerchantSidekick::Gateway.gateway         = nil
  end

  it "should read config" do
    MerchantSidekick::ActiveMerchant::Gateways::PaypalGateway.config[:api_username].should == "seller_XYZ_biz_api1.example.com"
    MerchantSidekick::ActiveMerchant::Gateways::PaypalGateway.config[:api_password].should == "ABCDEFG123456789"
    MerchantSidekick::ActiveMerchant::Gateways::PaypalGateway.config[:signature].should == "AsPC9BjkCyDFQXbStoZcgqH3hpacAX3IenGazd35.nEnXJKR9nfCmJDu"
  end

  it "should return active merchant paypal gateway instance" do
    MerchantSidekick::ActiveMerchant::Gateways::PaypalGateway.gateway.should be_instance_of(::ActiveMerchant::Billing::PaypalGateway)
  end

  after(:all) do
    MerchantSidekick::Gateway.default_gateway = ActiveMerchant::Billing::BogusGateway.new
  end

end
