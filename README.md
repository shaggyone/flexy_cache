# FlexyCache

Caches values for method calls. When cached value is expired, tries to refresh it. If refresh is failed for some reason, returns value stored in cache. Usefull for interacting with unstable web services, providing some unfrequently changed data.

## Installation

Add this line to your application's Gemfile:

    gem 'flexy_cache'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install flexy_cache

Configure redis, which is used to store cached values.

## Usage

    def calc_delivery_price from, to, weight
      # Some complex and time consuming logic, using web service.
      # Data on we service is'nt refresshed very often.
    end

    flexy_cache :calc_delivery_price,
                :cache_key_condition => Proc.new { |object, method_name, from, to, weight| calculate_cache_key },
                :expired_on          => Proc.new { |object| Time.now + 2.weeks },    # When successfully cached data will be tried to refresh.
                :retry_in            => Proc.new { |object| Time.now + 2.hours },    # When unsuccessfully refreshed data will be tried to refresh again.
                :error_result        => Proc.new { |result, object| result.blank? }, # When treat result as unsuccessfull, and cached value should be returned.
                :catch_exceptions    => Net::HTTPExceptions                          # Theese exceptions will be catched and cached value will be returned, if exists.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
