# 6.times do |i|
#   ValuesRecorder.record('a1', i)
# end
# a = ValuesRecorder.fetch('a1')

# ValuesRecorder
# by Simone Dall'Angelo, 2014
# ---
# This library uses a redis connection to store multiple values
# inside some time-related values.
# It uses two values for each stored item, 1 for time (when happened)
# and 1 for the correlated value.
# By default each key can stores up to 100 stored values, when 101th
# value arrives the library drops the 1st.
# ---
# Library's methods:
# record(key, value_to_store):
#   this method stores a new value for 'key' key passed as argument
#   in "#{key}_time" when record happened
#   in "#{key}_values" the correlated value
#
# fetch(key):
#   this method retrieve all stored values for the passed 'key'
#
# reset!(key):
#   this method empty the passed 'key' and return deleted items
#
# ---

# $redis ||= Redis.new(:url => 'redis://127.0.0.1:6379')

module ValuesRecorder
  class << self

    @@max_items = 100

    # Usage: ValuesRecorder.record(key, value_to_store)
    def record(key, value_to_store)
      # If $redis is not available, it tries to create the redis connection
      $redis ||= Redis.new(:url => 'redis://127.0.0.1:6379')

      prepend = (defined?(Rails) ? Rails.env + '_' : '')
      
      # Used for 'when' happened
      key_for_time = prepend + key + '_time'
      # Used for actual data
      key_for_value = prepend + key + '_values'

      now = Time.now.utc.to_i

      if $redis.llen(key_for_value) >= @@max_items
        # The list is full, delete an item and add the new one
        $redis.multi do
          $redis.lpop(key_for_time)
          $redis.lpop(key_for_value)
        end
      end
      # Adding
      $redis.multi do
        $redis.rpush(key_for_time, now.to_s)
        $redis.rpush(key_for_value, value_to_store.to_s)
      end
    end
    
    # Usage: ValuesRecorder.fetch(key) => up to 100 items
    def fetch(key)
      # If $redis is not available, it tries to create the redis connection
      $redis ||= Redis.new(:url => 'redis://127.0.0.1:6379')

      # Used for 'when' happened
      prepend = (defined?(Rails) ? Rails.env + '_' : '')
      key_for_time = prepend + key + '_time'
      # Used for actual data
      key_for_value = prepend + key + '_values'

      data = {:time => [], :values => []}

      data[:time] = $redis.lrange(key_for_time, 0, @@max_items - 1)
      data[:values] = $redis.lrange(key_for_value, 0, @@max_items - 1)

      return data
    end

    # Usage: ValuesRecorder.reset!(key) => deletes passed key and all stored values
    def reset!(key)
      # If $redis is not available, it tries to create the redis connection
      $redis ||= Redis.new(:url => 'redis://127.0.0.1:6379')

      prepend = (defined?(Rails) ? Rails.env + '_' : '')

      # Used for 'when' happened
      key_for_time = prepend + key + '_time'
      # Used for actual data
      key_for_value = prepend + key + '_values'

      $redis.del(key_for_value, key_for_time)
    end
  end
end
