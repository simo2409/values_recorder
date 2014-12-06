# ValuesRecorder #

*by Simone Dall'Angelo, 2014*

---
This library uses a redis connection (it should be already available in $redis) to store
multiple values inside some time-related values.
It uses two values for each stored item, 1 for time (when happened)
and 1 for the correlated value.
By default each key can stores up to 100 stored values, when 101th value arrives the library drops the 1st.
---

## API ##

Library's methods:

**record(key, value_to_store)**

  this method stores a new value for 'key' key passed as argument
  in "#{key}_time" when record happened
  in "#{key}_values" the correlated value

**fetch(key)**

  this method retrieve all stored values for the passed 'key'.
  Both time and values are **always** strings (as they arrive from redis)

**reset!(key)**

  this method empty the passed 'key' and return deleted items