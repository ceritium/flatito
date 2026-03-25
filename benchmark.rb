# frozen_string_literal: true

require "English"
require "flatito"

# --- Helpers ---

def measure_time(times, &block)
  gc_was_disabled = GC.disable
  start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  times.times(&block)
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
  GC.enable unless gc_was_disabled
  elapsed
end

def measure_memory
  GC.start
  GC.compact if GC.respond_to?(:compact)
  before_mem = `ps -o rss= -p #{$PROCESS_ID}`.strip.to_i
  before_gc = GC.stat[:total_allocated_objects]

  yield

  after_gc = GC.stat[:total_allocated_objects]
  after_mem = `ps -o rss= -p #{$PROCESS_ID}`.strip.to_i

  { rss_kb: after_mem - before_mem, objects: after_gc - before_gc }
end

def report(label, times, &block)
  # Warmup
  3.times(&block)

  elapsed = measure_time(times, &block)
  mem = measure_memory { times.times(&block) }
  per_iter = (elapsed / times * 1000).round(3)

  puts format(
    "  %-40s %8.3f ms/iter  |  RSS: %+6d KB  |  Allocs: %d",
    label, per_iter, mem[:rss_kb], mem[:objects]
  )
end

# --- Setup ---

yaml_small = (1..100).map { |i| "key_#{i}: Value number #{i}" }.join("\n")
yaml_medium = (1..1000).map { |i| "key_#{i}: Value number #{i} with some extra text" }.join("\n")

nested_lines = (1..200).map do |i|
  "group_#{i / 10}:\n  key_#{i}: Value number #{i} with nested content"
end
yaml_nested = nested_lines.join("\n")

json_content = "{\n" + (1..1000).map { |i| "  \"key_#{i}\": \"Value number #{i}\"" }.join(",\n") + "\n}"

items_medium = Flatito::FlattenYaml.items_from_content(yaml_medium)

null_io = File.open(File::NULL, "w")
Flatito::Config.stdout = null_io
Flatito::Config.prepare_with_options({ no_color: true })

# --- Benchmark ---

puts "Flatito Benchmark"
puts "Ruby #{RUBY_VERSION} | #{RUBY_PLATFORM}"
puts "=" * 90

puts "\n[Parsing]"
report("YAML 100 keys", 1000) { Flatito::FlattenYaml.items_from_content(yaml_small) }
report("YAML 1000 keys", 500) { Flatito::FlattenYaml.items_from_content(yaml_medium) }
report("YAML 200 nested keys", 500) { Flatito::FlattenYaml.items_from_content(yaml_nested) }
report("JSON 1000 keys", 500) { Flatito::FlattenYaml.items_from_content(json_content) }

puts "\n[Filtering]"
pi = Flatito::PrintItems.new("key_50")
report("by key (literal)", 5000) { pi.filter_by_search(items_medium) }

pi = Flatito::PrintItems.new("key_(5|9)\\d\\d")
report("by key (regex)", 5000) { pi.filter_by_search(items_medium) }

if Flatito::PrintItems.instance_method(:initialize).arity.abs > 1
  pi = Flatito::PrintItems.new(nil, "number 50")
  report("by value (literal)", 5000) { pi.filter_by_value(items_medium) }

  pi = Flatito::PrintItems.new(nil, "number (5|9)\\d\\d")
  report("by value (regex)", 5000) { pi.filter_by_value(items_medium) }

  pi = Flatito::PrintItems.new("key_5", "number 5")
  report("by key + value", 5000) do
    filtered = pi.filter_by_search(items_medium)
    pi.filter_by_value(filtered)
  end
end

puts "\n[Rendering]"
Flatito::Config.prepare_with_options({})
pi = Flatito::PrintItems.new("key_50")
report("filter + print (key, 11 matches)", 2000) { pi.print(items_medium) }

if Flatito::PrintItems.instance_method(:initialize).arity.abs > 1
  pi = Flatito::PrintItems.new(nil, "number 50")
  report("filter + print (value, 11 matches)", 2000) { pi.print(items_medium) }
end

pi = Flatito::PrintItems.new(nil)
report("print all (1000 items, no filter)", 20) { pi.print(items_medium) }

puts "\n[Memory - large parse]"
GC.start
GC.compact if GC.respond_to?(:compact)
before = GC.stat[:total_allocated_objects]
rss_before = `ps -o rss= -p #{$PROCESS_ID}`.strip.to_i
large_yaml = (1..5000).map { |i| "key_#{i}: Value number #{i} with a longer description to simulate real data" }.join("\n")
Flatito::FlattenYaml.items_from_content(large_yaml)
after = GC.stat[:total_allocated_objects]
rss_after = `ps -o rss= -p #{$PROCESS_ID}`.strip.to_i
puts format("  %-40s RSS: %+6d KB  |  Allocs: %d", "parse 5000 keys YAML", rss_after - rss_before, after - before)

null_io.close
puts "\n#{"=" * 90}"
