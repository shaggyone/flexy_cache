require 'json'

module FlexyCache
  module Storage
    # Stores value in key values store.
    #
    # @param [String]   key       Key for stored value.
    # @param [String]   value     Stored value.
    # @param [DateTime] expire_on When the value will be expired.
    #
    # @return [String]  stored_value.
    def store_value(key, value, expire_on)
      $flexy_cache_redis.set key, {
                                    :expire_on => expire_on,
                                    :value     => value
                                  }
    end

    # Updates expiration time for stored value.
    #
    # @param [String]   key        Key for stored value.
    # @param [DateTime] expired_on When the value will be expired.
    #
    # @return [DateTime] Stored value of expire_on.
    def update_value_expiration(key, expire_on)
      val = $flexy_cache_redis.get(key)
      if val
        val[:expire_on] = expire_on
        $flexy_cache_redis.set(key, val)
      end
    end

    # Retrieves stored_value.
    #
    # @param [String]   key       Key for stored value.
    #
    # @return [Array<String, DateTine>]  stored_value and expiretion_time.
    def get_value(key)
      val = $flexy_cache_redis.get(key)
      [val[:value], val[:expire_on]] if val
    end

    # Returns true if value is stored, otherwise returns false.
    #
    # @param [String]   key        Key for stored value.
    #
    # @return [true, false]
    def value_stored?(key)
      !!$flexy_cache_redis.get(key)
    end
  end
end
