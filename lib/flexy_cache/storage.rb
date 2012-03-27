require 'json'

module FlexyCache
  class Storage
    attr_accessor :redis

    def initialize(redis)
      @redis = redis
    end

    # Stores value in key values store.
    #
    # @param [String]   key       Key for stored value.
    # @param [String]   value     Stored value.
    # @param [DateTime] expire_on When the value will be expired.
    #
    # @return [String]  stored_value.
    def store_value(key, value, expire_on)
      set key, {
                 "expire_on" => expire_on,
                 "value"     => value
               }
      value
    end

    # Updates expiration time for stored value.
    #
    # @param [String]   key        Key for stored value.
    # @param [DateTime] expired_on When the value will be expired.
    #
    # @return [DateTime] Stored value of expire_on.
    def update_value_expiration(key, expire_on)
      val = get(key)
      if val
        val["expire_on"] = expire_on
        set key, val
      end
      expire_on
    end

    # Retrieves stored_value.
    #
    # @param [String]   key       Key for stored value.
    #
    # @return [Array<String, DateTine>]  stored_value and expiretion_time.
    def get_value(key)
      val = get(key)
      [val["value"], val["expire_on"]] if val
    end

    # Returns true if value is stored, otherwise returns false.
    #
    # @param [String]   key        Key for stored value.
    #
    # @return [true, false]
    def value_stored?(key)
      !!get(key)
    end

    def get(key)
      value = @redis.get(key)
      if value
        value = JSON.parse(value)
        value['expire_on'] = DateTime.parse value['expire_on']
      end
      value
    end

    def set(key, value)
      @redis.set key, JSON.dump(value)
    end
  end
end
