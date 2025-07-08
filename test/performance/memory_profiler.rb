#!/usr/bin/env ruby
# frozen_string_literal: true

# Memory profiler for Flatito - requires memory_profiler gem

begin
  require "memory_profiler"
rescue LoadError
  puts "Memory profiler requires the 'memory_profiler' gem."
  puts "Add it to your Gemfile or run: gem install memory_profiler"
  exit 1
end

require "bundler/setup"
require "flatito"

class FlatitoMemoryProfiler
  def initialize
    @test_files = [
      "test/fixtures/medium_file.yml",
      "test/fixtures/large_file.yml",
      "test/fixtures/huge_file.yml"
    ].select { |f| File.exist?(f) }
  end

  def profile_all
    puts "Flatito Memory Profiler"
    puts "=" * 40

    @test_files.each do |file_path|
      profile_file_processing(file_path)
      puts "\n" + ("-" * 40) + "\n"
    end

    profile_search_operations
  end

  private

  def profile_file_processing(file_path)
    puts "📁 Profiling file processing: #{File.basename(file_path)}"
    puts "File size: #{format("%.1f", File.size(file_path) / 1024.0)} KB"

    report = MemoryProfiler.report do
      items = Flatito::FlattenYaml.items_from_path(file_path)
      puts "Items loaded: #{items.length}"
    end

    puts "\nMemory Report:"
    puts "Total allocated: #{format("%.2f", report.total_allocated_memsize / (1024.0 * 1024.0))} MB"
    puts "Total retained: #{format("%.2f", report.total_retained_memsize / (1024.0 * 1024.0))} MB"
    puts "Objects allocated: #{report.total_allocated}"
    puts "Objects retained: #{report.total_retained}"

    puts "\nTop allocated object types:"
    report.allocated_memory_by_class.first(5).each do |class_name, data|
      printf "  %-20s %8.2f MB (%d objects)\n",
             class_name, data[:memsize] / (1024.0 * 1024.0), data[:count]
    end

    if report.retained_memory_by_class.any?
      puts "\nTop retained object types:"
      report.retained_memory_by_class.first(5).each do |class_name, data|
        printf "  %-20s %8.2f MB (%d objects)\n",
               class_name, data[:memsize] / (1024.0 * 1024.0), data[:count]
      end
    end
  end

  def profile_search_operations
    return if @test_files.empty?

    file_path = @test_files.last # Use the largest available file
    puts "🔍 Profiling search operations on: #{File.basename(file_path)}"

    # Load data once
    items = Flatito::FlattenYaml.items_from_path(file_path)
    puts "Dataset size: #{items.length} items"

    # Profile key search
    puts "\nProfiling key search..."
    report = MemoryProfiler.report do
      print_items = Flatito::PrintItems.new("metadata", nil)
      filtered = print_items.filter_by_search(items)
      puts "Key search results: #{filtered.length} items"
    end

    puts "Key search memory usage: #{format("%.2f", report.total_allocated_memsize / (1024.0 * 1024.0))} MB"

    # Profile value search
    puts "\nProfiling value search..."
    report = MemoryProfiler.report do
      print_items = Flatito::PrintItems.new(nil, "performance")
      filtered = print_items.filter_by_value(items)
      puts "Value search results: #{filtered.length} items"
    end

    puts "Value search memory usage: #{format("%.2f", report.total_allocated_memsize / (1024.0 * 1024.0))} MB"
  end
end

# Add memory_profiler to development dependencies if not already there
def check_memory_profiler_dependency
  gemfile_content = File.read("Gemfile")
  return if gemfile_content.include?("memory_profiler")

  puts "\n💡 Tip: Add 'memory_profiler' to your Gemfile for easier profiling:"
  puts 'gem "memory_profiler", group: :development'
end

if __FILE__ == $PROGRAM_NAME
  profiler = FlatitoMemoryProfiler.new
  profiler.profile_all
  check_memory_profiler_dependency
end
