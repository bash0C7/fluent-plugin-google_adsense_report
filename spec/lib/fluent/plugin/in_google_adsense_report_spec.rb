require 'spec_helper'

describe do
  let(:driver) {
    AWS.stub!
    Fluent::Test::InputTestDriver.new(Fluent::GoogleAdsenseReportInput).configure(config)
  }
  let(:instance) {driver.instance}

  describe 'emit' do

    #@client.executeの引数が想定通りのものが引きわたっていることを確認する

  end

end