require 'rubygems'
require 'bundler/setup'

require 'redis'
require 'rspec/expectations'
require 'timecop'

require_relative '../values_recorder'

describe ValuesRecorder do
  it "Calling ValuesRecorder.fetch('not_existing_key') should return empty data" do
    data = ValuesRecorder.fetch('not_existing_key')
    expect(data).to eq({:time => [], :values => []})
  end
  it "Calling once ValuesRecorder.record(key, value) should store the new value" do
    # Resetting
    ValuesRecorder.reset!('foo')

    # Freezing time
    now = Time.now
    Timecop.freeze(now)

    ValuesRecorder.record('foo', 123)
    new_datum = ValuesRecorder.fetch('foo')
    expect(new_datum).to eq({:time => [now.utc.to_i.to_s], :values => ['123']})
  end
  it "Calling multiple times ValuesRecorder.record(key, value) should store all values" do
    # Resetting
    ValuesRecorder.reset!('foo')

    # Freezing time
    now = Time.now
    Timecop.freeze(now)

    ValuesRecorder.record('foo', 123)

    # Move on by 1 second
    new_now = now + 1 # + 1 second
    Timecop.freeze(new_now)
    ValuesRecorder.record('foo', 124)

    new_datum = ValuesRecorder.fetch('foo')
    expect(new_datum).to eq({:time => [now.utc.to_i.to_s, new_now.utc.to_i.to_s], :values => ['123', '124']})
  end
  it "Calling ValuesRecorder.record(key, value) for 100 time I should see all 100 values" do
    # Resetting
    ValuesRecorder.reset!('foo')

    # Freezing time
    now = Time.now
    Timecop.freeze(now)

    (0..99).each do |ind|
      new_now = now + ind # ind seconds
      Timecop.freeze(new_now)
      ValuesRecorder.record('foo', ind)
    end

    all_data = ValuesRecorder.fetch('foo')
    
    expect(all_data[:time].size).to be(100)
    expect(all_data[:values].size).to be(100)
  end
  it "Calling ValuesRecorder.record(key, value) for 101 time I should see only last 100 values" do
    # Resetting
    ValuesRecorder.reset!('foo')

    # Freezing time
    now = Time.now
    Timecop.freeze(now)

    (0..99).each do |ind|
      new_now = now + ind # ind seconds
      Timecop.freeze(new_now)
      ValuesRecorder.record('foo', ind)
    end

    all_data = ValuesRecorder.fetch('foo')
    
    first_time = all_data[:time][0]
    first_value = all_data[:values][0]

    # Explicit check for first value
    expect(all_data[:time]).to include(first_time)
    expect(all_data[:values]).to include(first_value)

    # Now I have 100 items, adding 1 more
    now = now + 200
    ValuesRecorder.record('foo', 200)
    all_data = ValuesRecorder.fetch('foo')

    # Checks that items are still 100
    expect(all_data[:time].size).to be(100)
    expect(all_data[:values].size).to be(100)

    # Check that first value is not present anymore
    expect(all_data[:time]).to_not include(first_time)
    expect(all_data[:values]).to_not include(first_value)
  end
  it "Calling ValuesRecorder.reset('existing_key') should reset the passed key" do
    # Resetting
    ValuesRecorder.reset!('foo')

    # Insert one value
    ValuesRecorder.record('foo', 200)
    all_data = ValuesRecorder.fetch('foo')

    expect(all_data[:time].size).to eq(1)
    expect(all_data[:values].size).to eq(1)

    ValuesRecorder.reset!('foo')
    all_data = ValuesRecorder.fetch('foo')

    expect(all_data).to eq({:time => [], :values => []})

  end
end