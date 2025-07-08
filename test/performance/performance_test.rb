# frozen_string_literal: true

require "test_helper"
require "benchmark"
require "objspace"

class PerformanceTest < Minitest::Test
  # Memory monitoring utilities
  def measure_memory_usage
    GC.start # Ensure clean state
    GC.disable # Prevent GC during measurement

    memory_before = ObjectSpace.memsize_of_all
    yield
    memory_after = ObjectSpace.memsize_of_all

    GC.enable
    GC.start

    memory_after - memory_before
  end

  def measure_object_allocations
    objects_before = ObjectSpace.count_objects
    yield
    objects_after = ObjectSpace.count_objects

    {
      total_allocated: objects_after[:TOTAL] - objects_before[:TOTAL],
      strings: objects_after[:T_STRING] - objects_before[:T_STRING],
      arrays: objects_after[:T_ARRAY] - objects_before[:T_ARRAY],
      hashes: objects_after[:T_HASH] - objects_before[:T_HASH]
    }
  end

  def measure_cpu_time
    user_time_before = Process.times.utime
    system_time_before = Process.times.stime

    result = yield

    user_time_after = Process.times.utime
    system_time_after = Process.times.stime

    {
      result: result,
      user_time: user_time_after - user_time_before,
      system_time: system_time_after - system_time_before,
      total_time: (user_time_after - user_time_before) + (system_time_after - system_time_before)
    }
  end

  def performance_summary(description, cpu_data, memory_bytes, allocations)
    puts "\n" + ("=" * 60)
    puts "PERFORMANCE REPORT: #{description}"
    puts "=" * 60
    printf "CPU Time (user):    %.4f seconds\n", cpu_data[:user_time]
    printf "CPU Time (system):  %.4f seconds\n", cpu_data[:system_time]
    printf "CPU Time (total):   %.4f seconds\n", cpu_data[:total_time]
    printf "Memory Usage:       %.2f MB\n", memory_bytes / (1024.0 * 1024.0)
    puts "Object Allocations:"
    printf "  Total:            %d objects\n", allocations[:total_allocated]
    printf "  Strings:          %d objects\n", allocations[:strings]
    printf "  Arrays:           %d objects\n", allocations[:arrays]
    printf "  Hashes:           %d objects\n", allocations[:hashes]
    puts "=" * 60
  end

  # Performance tests for different file sizes
  test "performance with small file" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    file_path = "test/fixtures/no_nested.yml"

    allocations = measure_object_allocations do
      memory_usage = measure_memory_usage do
        cpu_data = measure_cpu_time do
          Flatito::FlattenYaml.items_from_path(file_path)
        end
        @cpu_data = cpu_data
      end
      @memory_usage = memory_usage
    end

    performance_summary("Small file (#{file_path})", @cpu_data, @memory_usage, allocations)

    # Basic assertions for small files
    assert_operator @cpu_data[:total_time], :<, 0.1, "Small file processing should be very fast"
    assert_operator @memory_usage, :<, 1024 * 1024, "Small file should use less than 1MB"
  end

  test "performance with medium file" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    file_path = "test/fixtures/medium_file.yml"

    allocations = measure_object_allocations do
      memory_usage = measure_memory_usage do
        cpu_data = measure_cpu_time do
          Flatito::FlattenYaml.items_from_path(file_path)
        end
        @cpu_data = cpu_data
      end
      @memory_usage = memory_usage
    end

    performance_summary("Medium file (#{file_path})", @cpu_data, @memory_usage, allocations)

    # Reasonable limits for medium files
    assert_operator @cpu_data[:total_time], :<, 1.0, "Medium file processing should complete within 1 second"
    assert_operator @memory_usage, :<, 10 * 1024 * 1024, "Medium file should use less than 10MB"
  end

  test "performance with large file" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    file_path = "test/fixtures/large_file.yml"

    allocations = measure_object_allocations do
      memory_usage = measure_memory_usage do
        cpu_data = measure_cpu_time do
          Flatito::FlattenYaml.items_from_path(file_path)
        end
        @cpu_data = cpu_data
      end
      @memory_usage = memory_usage
    end

    performance_summary("Large file (#{file_path})", @cpu_data, @memory_usage, allocations)

    # Generous limits for large files
    assert_operator @cpu_data[:total_time], :<, 2.0, "Large file processing should complete within 2 seconds"
    assert_operator @memory_usage, :<, 50 * 1024 * 1024, "Large file should use less than 50MB"
  end

  test "performance with huge file" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    file_path = "test/fixtures/huge_file.yml"

    allocations = measure_object_allocations do
      memory_usage = measure_memory_usage do
        cpu_data = measure_cpu_time do
          Flatito::FlattenYaml.items_from_path(file_path)
        end
        @cpu_data = cpu_data
      end
      @memory_usage = memory_usage
    end

    performance_summary("Huge file (#{file_path})", @cpu_data, @memory_usage, allocations)

    # Monitor but don't fail on huge files - just report
    if @cpu_data[:total_time] > 5.0
      puts "WARNING: Huge file took #{format("%.4f", @cpu_data[:total_time])}s"
    end
    if @memory_usage > 100 * 1024 * 1024
      puts "WARNING: Huge file used #{format("%.2f", @memory_usage / (1024.0 * 1024.0))}MB"
    end
  end

  # Performance tests for search operations
  test "search performance on large dataset" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    file_path = "test/fixtures/huge_file.yml"

    # First load the data
    items = Flatito::FlattenYaml.items_from_path(file_path)
    print_items = Flatito::PrintItems.new("metadata", nil)

    # Test key search performance
    allocations = measure_object_allocations do
      memory_usage = measure_memory_usage do
        cpu_data = measure_cpu_time do
          print_items.filter_by_search(items)
        end
        @cpu_data = cpu_data
      end
      @memory_usage = memory_usage
    end

    performance_summary("Key search on huge dataset", @cpu_data, @memory_usage, allocations)

    assert_operator @cpu_data[:total_time], :<, 1.0, "Key search should be fast even on large datasets"
  end

  test "value search performance on large dataset" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    file_path = "test/fixtures/huge_file.yml"

    # First load the data
    items = Flatito::FlattenYaml.items_from_path(file_path)
    print_items = Flatito::PrintItems.new(nil, "performance")

    # Test value search performance
    allocations = measure_object_allocations do
      memory_usage = measure_memory_usage do
        cpu_data = measure_cpu_time do
          print_items.filter_by_value(items)
        end
        @cpu_data = cpu_data
      end
      @memory_usage = memory_usage
    end

    performance_summary("Value search on huge dataset", @cpu_data, @memory_usage, allocations)

    assert_operator @cpu_data[:total_time], :<, 1.0, "Value search should be fast even on large datasets"
  end

  # Memory leak detection
  test "memory leak detection during repeated operations" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    file_path = "test/fixtures/medium_file.yml"
    iterations = 10
    memory_samples = []

    iterations.times do |i|
      GC.start
      # memory_before = ObjectSpace.memsize_of_all

      # Perform the operation
      items = Flatito::FlattenYaml.items_from_path(file_path)
      print_items = Flatito::PrintItems.new("metadata", "performance")
      print_items.filter_by_search(items)
      print_items.filter_by_value(items)

      GC.start
      memory_after = ObjectSpace.memsize_of_all
      memory_samples << memory_after

      puts "Iteration #{i + 1}: Memory usage #{format("%.2f", memory_after / (1024.0 * 1024.0))}MB"
    end

    # Check for memory leaks - memory usage should be relatively stable
    first_half = memory_samples[0...(iterations / 2)]
    second_half = memory_samples[(iterations / 2)..-1]

    avg_first_half = first_half.sum / first_half.length
    avg_second_half = second_half.sum / second_half.length

    growth_percentage = ((avg_second_half - avg_first_half) / avg_first_half.to_f) * 100

    puts "\nMemory growth analysis:"
    puts "First half average: #{format("%.2f", avg_first_half / (1024.0 * 1024.0))}MB"
    puts "Second half average: #{format("%.2f", avg_second_half / (1024.0 * 1024.0))}MB"
    puts "Growth: #{format("%.2f", growth_percentage)}%"

    # Fail if memory growth is significant (more than 20%)
    assert_operator growth_percentage, :<, 20, "Potential memory leak detected: #{format("%.2f", growth_percentage)}% growth"
  end

  # Benchmark comparison: before vs after our truncation fix
  test "performance comparison: truncated vs full values" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"

    file_path = "test/fixtures/large_file.yml"

    # Test current implementation (full values)
    puts "\nTesting current implementation (full values)..."
    current_time = Benchmark.realtime do
      items = Flatito::FlattenYaml.items_from_path(file_path)
      print_items = Flatito::PrintItems.new(nil, "very_long")
      print_items.filter_by_value(items)
    end

    puts "Current implementation time: #{format("%.4f", current_time)}s"

    # The old implementation would have truncated values, making this search fail
    # We can't easily test the old implementation, but we can verify our fix works
    items = Flatito::FlattenYaml.items_from_path(file_path)
    print_items = Flatito::PrintItems.new(nil, "very_long")
    filtered = print_items.filter_by_value(items)

    puts "Found #{filtered.length} items with long values"

    assert_operator filtered.length, :>, 0, "Should find items with long values (proving our fix works)"
  end

  # Stress test with massive file
  test "stress test with massive dataset" do
    skip "Performance tests only run when PERFORMANCE=1" unless ENV["PERFORMANCE"] == "1"
    skip "Massive file stress test only runs with STRESS_TEST=1" unless ENV["STRESS_TEST"] == "1"

    file_path = "test/fixtures/massive_file.yml"

    puts "\n" + ("!" * 60)
    puts "STRESS TEST: Processing massive dataset"
    puts "!" * 60

    allocations = measure_object_allocations do
      memory_usage = measure_memory_usage do
        cpu_data = measure_cpu_time do
          items = Flatito::FlattenYaml.items_from_path(file_path)
          print_items = Flatito::PrintItems.new("properties", "enabled")
          filtered = print_items.filter_by_search(items)
          print_items.filter_by_value(filtered)
        end
        @cpu_data = cpu_data
      end
      @memory_usage = memory_usage
    end

    performance_summary("STRESS TEST: Massive dataset", @cpu_data, @memory_usage, allocations)

    # Just report, don't fail on stress test
    puts "STRESS TEST COMPLETED"
    puts "Note: This test is for monitoring purposes only"
  end
end
