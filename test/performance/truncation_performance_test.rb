# frozen_string_literal: true

require "test_helper"
require "benchmark"
require "objspace"

# Test that our truncation fix maintains good performance
class TruncationPerformanceTest < Minitest::Test
  test "value filtering performance with long values is acceptable" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    # Create items with very long values to test our fix
    long_value = ("a" * 1000) + "searchable_text" + ("b" * 1000)
    items = []

    100.times do |i|
      items << Flatito::FlattenYaml::Item.new(
        key: "test_key_#{i}",
        value: long_value,
        line: i + 1
      )
    end

    print_items = Flatito::PrintItems.new(nil, "searchable_text")

    # Measure filtering performance
    time = Benchmark.realtime do
      filtered = print_items.filter_by_value(items)

      assert_equal 100, filtered.length, "Should find all items with long values"
    end

    # Should be very fast even with long values
    assert_operator time, :<, 0.1, "Value filtering should be fast even with long values, took #{time}s"
    puts "Value filtering with 100 long values took #{format("%.4f", time)}s"
  end

  test "memory usage with long values is reasonable" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    # Create items with various value lengths
    items = []

    # Mix of short and long values
    50.times do |i|
      short_value = "short_value_#{i}"
      long_value = "long_value_#{i}" + ("x" * 500) + "findme"

      items << Flatito::FlattenYaml::Item.new(key: "short_#{i}", value: short_value, line: i)
      items << Flatito::FlattenYaml::Item.new(key: "long_#{i}", value: long_value, line: i + 50)
    end

    GC.start
    memory_before = get_memory_usage_mb

    # Test both types of searches
    print_items_key = Flatito::PrintItems.new("long", nil)
    print_items_value = Flatito::PrintItems.new(nil, "findme")

    key_filtered = print_items_key.filter_by_search(items)
    value_filtered = print_items_value.filter_by_value(items)

    memory_after = get_memory_usage_mb
    memory_used = memory_after - memory_before

    assert_equal 50, key_filtered.length
    assert_equal 50, value_filtered.length

    # Memory usage should be reasonable (less than 10MB for this test)
    memory_mb = memory_used

    assert_operator memory_mb, :<, 10, "Memory usage should be reasonable, used #{format("%.2f", memory_mb)}MB"

    puts "Memory used for filtering 100 mixed items: #{format("%.2f", memory_mb)}MB"
  end

  private

  def get_memory_usage_mb
    GC.start
    # Use a simpler memory measurement approach
    ObjectSpace.count_objects[:TOTAL] * 40 / (1024.0 * 1024.0) # Rough estimate
  end
end
