require "flexy_cache/version"
require 'active_support/concern'

module FlexyCache
  extend ActiveSupport::Concern

  DEFAULT_OPTIONS = {
    :expired_on          => Proc.new { |object| Time.now + 2.weeks },    # When successfully cached data will be tried to refresh.
    :retry_in            => Proc.new { |object| Time.now + 2.hours },    # When unsuccessfully refreshed data will be tried to refresh again.
    :storage             => $flexy_key_value_storage
  }

  included do

  end


  module ClassMethods

    # Adds flexible caching to the given method.
    #
    # @param [Symbol] method_name Method name to add caching to.
    # @param [Hash]   options
    # @option :cache_key_condition [Proc] Proc used calculate caching key.
    # @option :expire_on           [Proc] Proc returning Time when the cached value should be expired.
    # @option :retry_in            [Proc] Proc returning Time when the unsuccessfull data refresh should be repeated.
    # @option :error_result        [Proc] Optional Proc used to analyse data retrieved from original proc contains an error value, so that cached value should be used.
    # @option :catch_exceptions    [Class, Array<Class>] Exception classes, than should be catched by flexy_cache, when any of the exceptions is catched, cached value is returned, otherwise the original exception is rerised.
    #
    # @returne [String] Returns value stored in cache or newly retrieved value.
    def flexy_cache method_name, options
      options = FlexyCache::DEFAULT_OPTIONS.merge(options)

      # Convert catched_exceptions list to array, if single exception given.
      catched_exceptions = [options[:catch_exceptions]].flatten

      # Make an alias, for using uncached method.
      alias_method "flexy_uncached_#{method_name}", method_name

      define_method method_name do |*args|

        # Cache timestamp
        timestamp = Time.now

        # Compute key, used for storing value.
        key = options[:cache_key_condition].call(self, method_name, *args)

        if $flexy_storage.value_stored?(key)

          # Get value from cache
          cached_value, expire_at = $flexy_storage.get_value(key)

          # Returns cached value unless expired
          return cached_value unless timestamp > expire_at

          # If value is expired try to refresh value
          begin
            uncached_value = self.send("flexy_uncached_#{method_name}", *args)

            # Test, if the value is error value.
            if options[:error_result]

              # Update cache expiration_time and return cached_value if error is returned.
              if options[:error_result].call(uncached_value, self)
                $flexy_storage.update_value_expiration(key, options[:retry_in].call(self))
                return cached_value
              end
            end

            # Store new value in cache and return it.
            return $flexy_storage.store_value key, uncached_value, options[:expire_on].call(self)
          rescue Exception => e

            # Return cached value if exception is in cached list.
            if catched_exceptions.find {|ex| e.is_a? ex }
              $flexy_storage.update_value_expiration(key, options[:retry_in].call(self))
              return cached_value
            end

            # Reraise exception otherwise.
            raise e
          end
        else
          uncached_value = self.send "flexy_uncached_#{method_name}", *args

          # Test, if the value is error value.
          if options[:error_result]

            # Update cache expiration_time and return cached_value if error is returned.
            return uncached_value if options[:error_result].call(uncached_value, self)
          end

          # Store new value in cache and return it.
          return $flexy_storage.store_value key, uncached_value, options[:expire_on].call(self)
        end
      end
    end
  end
end
