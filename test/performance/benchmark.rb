#!/usr/bin/env ruby
# frozen_string_literal: true

# Standalone performance benchmark script for Flatito

require "bundler/setup"
require "flatito"
require "benchmark"
require "objspace"

class FlatitoPerformanceBenchmark
  def initialize
    @results = {}
  end

  def run_all_benchmarks
    puts "Flatito Performance Benchmark Suite"
    puts "=" * 50
    puts "Ruby version: #{RUBY_VERSION}"
    puts "Flatito version: #{Flatito::VERSION}"
    puts "Time: #{Time.now}"
    puts "=" * 50

    run_file_size_benchmarks
    run_search_benchmarks
    run_memory_benchmarks

    print_summary
  end

  private

  def run_file_size_benchmarks
    puts "\n📂 File Size Performance Tests"
    puts "-" * 30

    test_files = [
      ["Small file", "test/fixtures/no_nested.yml"],
      ["Medium file", "test/fixtures/medium_file.yml"],
      ["Large file", "test/fixtures/large_file.yml"],
      ["Huge file", "test/fixtures/huge_file.yml"]
    ]

    test_files.each do |name, file_path|
      next unless File.exist?(file_path)

      benchmark_file_processing(name, file_path)
    end
  end

  def run_search_benchmarks
    puts "\n🔍 Search Performance Tests"
    puts "-" * 30

    file_path = "test/fixtures/huge_file.yml"
    return unless File.exist?(file_path)

    items = Flatito::FlattenYaml.items_from_path(file_path)
    puts "Dataset size: #{items.length} items"

    # Key search benchmark
    benchmark_search_operation("Key search", items) do |search_items|
      print_items = Flatito::PrintItems.new("metadata", nil)
      print_items.filter_by_search(search_items)
    end

    # Value search benchmark
    benchmark_search_operation("Value search", items) do |search_items|
      print_items = Flatito::PrintItems.new(nil, "performance")
      print_items.filter_by_value(search_items)
    end

    # Combined search benchmark
    benchmark_search_operation("Combined search", items) do |search_items|
      print_items = Flatito::PrintItems.new("properties", "enabled")
      filtered = print_items.filter_by_search(search_items)
      print_items.filter_by_value(filtered)
    end
  end

  def run_memory_benchmarks
    puts "\n💾 Memory Usage Tests"
    puts "-" * 30

    test_files = [
      ["Medium file", "test/fixtures/medium_file.yml"],
      ["Large file", "test/fixtures/large_file.yml"],
      ["Huge file", "test/fixtures/huge_file.yml"]
    ]

    test_files.each do |name, file_path|
      next unless File.exist?(file_path)

      benchmark_memory_usage(name, file_path)
    end
  end

  def benchmark_file_processing(name, file_path)
    file_size = File.size(file_path)

    memory_before = get_memory_usage

    time = Benchmark.realtime do
      @items = Flatito::FlattenYaml.items_from_path(file_path)
    end

    memory_after = get_memory_usage
    memory_used = memory_after - memory_before

    items_count = @items&.length || 0

    printf "%-15s %8.1f KB %6d items %8.4f sec %6.1f MB\n",
           name, file_size / 1024.0, items_count, time, memory_used / (1024.0 * 1024.0)

    @results[name] = {
      file_size: file_size,
      items: items_count,
      time: time,
      memory: memory_used
    }
  end

  def benchmark_search_operation(name, items)
    iterations = 5
    times = []

    iterations.times do
      time = Benchmark.realtime do
        yield(items)
      end
      times << time
    end

    avg_time = times.sum / times.length
    min_time = times.min
    max_time = times.max

    printf "%-20s %8.4f sec (avg) %8.4f sec (min) %8.4f sec (max)\n",
           name, avg_time, min_time, max_time

    @results[name] = {
      avg_time: avg_time,
      min_time: min_time,
      max_time: max_time
    }
  end

  def benchmark_memory_usage(name, file_path)
    GC.start
    GC.disable

    memory_before = ObjectSpace.memsize_of_all
    objects_before = ObjectSpace.count_objects

    items = Flatito::FlattenYaml.items_from_path(file_path)
    print_items = Flatito::PrintItems.new("metadata", "performance")
    print_items.filter_by_search(items)
    print_items.filter_by_value(items)

    memory_after = ObjectSpace.memsize_of_all
    objects_after = ObjectSpace.count_objects

    GC.enable
    GC.start

    memory_used = memory_after - memory_before
    objects_created = objects_after[:TOTAL] - objects_before[:TOTAL]

    printf "%-15s %8.1f MB %10d objects\n",
           name, memory_used / (1024.0 * 1024.0), objects_created
  end

  def get_memory_usage
    GC.start
    ObjectSpace.memsize_of_all
  end

  def print_summary
    puts "\n📊 Performance Summary"
    puts "=" * 50

    # File processing summary
    if @results.any? { |k, _| k.include?("file") }
      puts "\nFile Processing Performance:"
      printf "%-15s %10s %8s %10s %8s\n", "File", "Size", "Items", "Time", "Memory"
      printf "%-15s %10s %8s %10s %8s\n", "-" * 15, "-" * 10, "-" * 8, "-" * 10, "-" * 8

      @results.each do |name, data|
        next unless name.include?("file") && data[:file_size]

        printf "%-15s %8.1f KB %6d %8.4f s %6.1f MB\n",
               name, data[:file_size] / 1024.0, data[:items], data[:time], data[:memory] / (1024.0 * 1024.0)
      end
    end

    # Search performance summary
    if @results.any? { |k, _| k.include?("search") }
      puts "\nSearch Performance:"
      printf "%-20s %12s %12s %12s\n", "Operation", "Avg Time", "Min Time", "Max Time"
      printf "%-20s %12s %12s %12s\n", "-" * 20, "-" * 12, "-" * 12, "-" * 12

      @results.each do |name, data|
        next unless name.include?("search") && data[:avg_time]

        printf "%-20s %10.4f s %10.4f s %10.4f s\n",
               name, data[:avg_time], data[:min_time], data[:max_time]
      end
    end

    puts "\n✅ Benchmark completed successfully!"
    puts "\nTo run specific tests:"
    puts "  PERFORMANCE=1 bundle exec rake test (runs all performance tests)"
    puts "  ruby test/performance/benchmark.rb (runs this benchmark)"
  end
end

# Run the benchmark if this script is executed directly
if __FILE__ == $PROGRAM_NAME
  benchmark = FlatitoPerformanceBenchmark.new
  benchmark.run_all_benchmarks
end
