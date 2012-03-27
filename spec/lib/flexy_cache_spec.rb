require 'spec_helper'

describe FlexyCache do
  before :each do
    $flexy_storage = FlexyCache::Storage.new(Redis.new)
  end

  describe "flexy_cache" do
    let (:datetime) { Time.parse("2012-03-27 16:05") }
    subject { TestClass.new "test_object" }

    before(:each) do
      Timecop.freeze datetime do
        subject.value_to_return = 10.0
        subject.compute_delivery_price "sankt-peterburg", "krasnoyarsk", 0.01

        subject.value_to_return = 20.0
        subject.compute_delivery_price "sankt-peterburg", "krasnoyarsk", 0.11
      end
    end

    it "stores values in cache using correct key" do
      Timecop.freeze(datetime) do
        $flexy_storage.get("test_object->sankt-peterburg->krasnoyarsk->0.1")['value'].should be == 10.0
        $flexy_storage.get("test_object->sankt-peterburg->krasnoyarsk->0.1")['expire_on'].should be == Time.parse("2012-04-03 16:05")


        $flexy_storage.get("test_object->sankt-peterburg->krasnoyarsk->0.2")['value'].should be == 20.0
        $flexy_storage.get("test_object->sankt-peterburg->krasnoyarsk->0.2")['expire_on'].should be == Time.parse("2012-04-03 16:05")
      end
    end

    context "cache is not expired" do
      it "returns cached value at the second time if not expired"  do
        Timecop.freeze(datetime) do
          subject.value_to_return = 20.0
          subject.compute_delivery_price("sankt-peterburg", "krasnoyarsk", 0.01).should be == 10.0
        end
      end
    end

    context "cache is expired" do
      let (:time_in_future) { datetime + 8.days }

      before :each do
        Timecop.freeze(time_in_future)
      end

      after :each do
        Timecop.return
      end

      context "normal original proc action" do
        it "updates cached value when expired" do
          subject.value_to_return = 20.0

          subject.compute_delivery_price("sankt-peterburg", "krasnoyarsk", 0.01).should be == 20
          $flexy_storage.get("test_object->sankt-peterburg->krasnoyarsk->0.1")['expire_on'].should be == time_in_future + 7.days
        end
      end

      context "exception risen by original proc" do
        it "catches given exceptions and returnes cached value" do
          [CatchedExceptionA, CatchedExceptionB, CatchedExceptionC].each do |ex|
            subject.value_to_return = 20.0
            subject.raise_exception = ex

            lambda {
              subject.compute_delivery_price("sankt-peterburg", "krasnoyarsk", 0.01).should be == 10
             }.should_not raise_error
          end
        end

        it "reschedules refresh date if catched given exception" do
          subject.value_to_return = 20.0
          subject.raise_exception = CatchedExceptionA

          subject.compute_delivery_price("sankt-peterburg", "krasnoyarsk", 0.01).should be == 10.0
          $flexy_storage.get("test_object->sankt-peterburg->krasnoyarsk->0.1")['expire_on'].should be == time_in_future + 30.minutes
        end

        it "does not catch other exceptions" do
          subject.value_to_return = 20.0
          subject.raise_exception = UncatchedException

          lambda {
            subject.compute_delivery_price("sankt-peterburg", "krasnoyarsk", 0.01)
          }.should raise_error UncatchedException
        end
      end

      context "error value returned by original proc" do
        before :each do
          subject.value_to_return = nil
        end

        it "returns value from cache" do
          subject.compute_delivery_price("sankt-peterburg", "krasnoyarsk", 0.01).should be == 10.0
        end


        it "reschedules refresh date" do
          subject.compute_delivery_price("sankt-peterburg", "krasnoyarsk", 0.01)
          $flexy_storage.get("test_object->sankt-peterburg->krasnoyarsk->0.1")['expire_on'].should be == time_in_future + 30.minutes
        end
      end
    end
  end
end
