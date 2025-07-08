# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"

Minitest::TestTask.create

require "rubocop/rake_task"

RuboCop::RakeTask.new

# Performance testing tasks
namespace :performance do
  desc "Run performance tests"
  task :test do
    ENV["PERFORMANCE"] = "1"
    system("ruby -Ilib:test test/performance/performance_test.rb")
  end

  desc "Run benchmark suite"
  task :benchmark do
    system("ruby -Ilib test/performance/benchmark.rb")
  end

  desc "Run memory profiler (requires memory_profiler gem)"
  task :memory do
    system("ruby -Ilib test/performance/memory_profiler.rb")
  end

  desc "Run stress test with massive dataset"
  task :stress do
    ENV["PERFORMANCE"] = "1"
    ENV["STRESS_TEST"] = "1"
    system("ruby -Ilib:test test/performance/performance_test.rb")
  end

  desc "Generate performance test fixtures"
  task :fixtures do
    system("ruby test/performance/generate_fixtures.rb")
  end
end

task default: %i[test rubocop]
