require 'spec_helper'

require 'rack'
require 'stringio'

describe Pusher::WebHook do
  before :each do
    @hook_data = {
      "time_ms" => 123456,
      "events" => [
        {"name" => 'foo'}
      ]
    }
  end

  describe "initialization" do
    it "can be initialized with Rack::Request" do
      request = Rack::Request.new({
        'HTTP_X_PUSHER_APPKEY' => '1234',
        'HTTP_X_PUSHER_HMAC_SHA256' => 'asdf',
        'CONTENT_TYPE' => 'application/json',
        'rack.input' => StringIO.new(MultiJson.encode(@hook_data))
      })
      wh = Pusher::WebHook.new(request)
      wh.key.should == '1234'
      wh.signature.should == 'asdf'
      wh.data.should == @hook_data
    end

    it "can be initialized with a hash" do
      request = {
        key: '1234',
        signature: 'asdf',
        content_type: 'application/json',
        body: MultiJson.encode(@hook_data),
      }
      wh = Pusher::WebHook.new(request)
      wh.key.should == '1234'
      wh.signature.should == 'asdf'
      wh.data.should == @hook_data
    end
  end

  describe "after initialization" do
    before :each do
      body = MultiJson.encode(@hook_data)
      request = {
        key: '1234',
        signature: HMAC::SHA256.hexdigest('asdf', body),
        content_type: 'application/json',
        body: body
      }
      @wh = Pusher::WebHook.new(request)
    end

    it "should validate" do
      Pusher.key = '1234'
      Pusher.secret = 'asdf'
      @wh.should be_valid
    end

    it "should not validate if secret is wrong" do
      Pusher.key = '1234'
      Pusher.secret = 'asdfxxx'
      Pusher.logger.should_receive(:warn).with("Received WebHook with invalid signature: got a18bd1374b3b198ec457fb11d636ee2024d8077fc542829443729988bd1e4aa4, expected bb81a112a46dee1e4154ee4f328621f32558192c7af12adfc0395082cfcd3c6c")
      @wh.should_not be_valid
    end

    it "should expose events" do
      @wh.events.should == @hook_data["events"]
    end

    it "should expose time" do
      @wh.time.should == Time.at(123.456)
    end
  end
end