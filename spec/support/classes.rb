class CatchedExceptionA < Exception
end

class CatchedExceptionB < Exception
end

class CatchedExceptionC < CatchedExceptionB
end

class UncatchedException < Exception
end

class TestClass
  include FlexyCache

  attr_accessor :raise_exception
  attr_accessor :value_to_return

  attr_accessor :name

  def initialize name
    self.name = name
  end

  def compute_delivery_price from, to, weight
    raise @raise_exception if @raise_exception
    return @value_to_return
  end

  flexy_cache :compute_delivery_price,
    :cache_key_condition => Proc.new { |object, method_name, from, to, weight| "#{object.name}->#{from}->#{to}->#{(weight/0.1).ceil * 0.1}" },
    :expire_on => Proc.new { Time.now + 1.week },
    :retry_in  => Proc.new { Time.now + 30.minutes },
    :error_result => Proc.new { |value, object| value.nil? },
    :catch_exceptions => [CatchedExceptionA, CatchedExceptionB]

end

