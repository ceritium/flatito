# Performance Testing for Flatito

This directory contains comprehensive performance tests and benchmarks for the Flatito gem, focusing on memory footprint and CPU usage optimization.

## Overview

The performance test suite includes:

- **Memory usage monitoring** - Track memory allocation and detect potential leaks
- **CPU time measurement** - Monitor user and system time consumption
- **Object allocation tracking** - Count allocated objects by type
- **Scalability testing** - Test with files of varying sizes
- **Search performance** - Benchmark key and value search operations
- **Memory leak detection** - Repeated operation monitoring

## Files

### Test Files

- `performance_test.rb` - Main performance test suite using Minitest
- `benchmark.rb` - Standalone benchmark script with detailed reporting
- `memory_profiler.rb` - Memory profiling using the memory_profiler gem
- `generate_fixtures.rb` - Script to generate large test files

### Test Fixtures

The performance tests use several fixture files of different sizes:

- `test/fixtures/no_nested.yml` - Small file (3 items)
- `test/fixtures/medium_file.yml` - Medium file (100 items)  
- `test/fixtures/large_file.yml` - Large file (manual, ~150 items)
- `test/fixtures/huge_file.yml` - Huge file (1,000 items)
- `test/fixtures/massive_file.yml` - Massive file (5,000 items)

## Running Performance Tests

### Quick Start

```bash
# Generate test fixtures (run once)
rake performance:fixtures

# Run basic benchmark
rake performance:benchmark

# Run comprehensive performance tests
rake performance:test

# Run memory profiler (requires memory_profiler gem)
gem install memory_profiler
rake performance:memory

# Run stress test with massive dataset
rake performance:stress
```

### Manual Execution

```bash
# Run specific performance tests
PERFORMANCE=1 ruby -Ilib:test test/performance/performance_test.rb

# Run standalone benchmark
ruby -Ilib test/performance/benchmark.rb

# Run memory profiler
ruby -Ilib test/performance/memory_profiler.rb
```

## Performance Metrics

### Memory Usage

The tests monitor several memory-related metrics:

- **Total memory allocation** - Peak memory usage during operations
- **Object allocation** - Number and types of objects created
- **Memory leaks** - Memory growth over repeated operations
- **Garbage collection** - Impact of GC on performance

### CPU Performance

CPU performance is measured using:

- **User time** - Time spent in application code
- **System time** - Time spent in system calls
- **Total time** - Combined user + system time
- **Benchmark iterations** - Multiple runs for statistical accuracy

### Expected Performance Characteristics

Based on the current implementation:

#### File Processing Performance
- **Small files** (< 1KB): < 0.1s, < 1MB memory
- **Medium files** (~ 50KB): < 1.0s, < 10MB memory  
- **Large files** (~ 200KB): < 2.0s, < 50MB memory
- **Huge files** (~ 500KB): Monitored but no hard limits

#### Search Performance
- **Key search**: Should be very fast (< 1s) even on large datasets
- **Value search**: Should remain fast despite full value storage
- **Combined search**: Reasonable performance for filtered operations

## Performance Optimization Areas

### Memory Optimization

1. **Value Storage**: Our fix stores full values instead of truncated ones
   - Trade-off: Higher memory usage for better search functionality
   - Mitigation: Truncation only happens at display time

2. **Object Allocation**: Monitor allocation of strings, arrays, and hashes
   - YAML parsing creates many temporary objects
   - Consider streaming or lazy loading for very large files

3. **Garbage Collection**: Frequent GC can impact performance
   - Tests disable GC during measurements for accuracy
   - Real usage benefits from Ruby's automatic GC

### CPU Optimization

1. **Regex Operations**: Search filtering uses regex matching
   - Compiled regexes are cached for reuse
   - Consider optimization for very frequent searches

2. **File I/O**: Large file reading can be I/O bound
   - Current implementation reads entire files into memory
   - Consider streaming for massive files

## Memory Leak Detection

The test suite includes memory leak detection that:

1. Runs operations repeatedly (10 iterations)
2. Measures memory usage after each iteration
3. Compares first half vs second half averages
4. Fails if growth exceeds 20%

This helps catch memory leaks early in development.

## Performance Regression Testing

These tests can be integrated into CI/CD pipelines to:

- Monitor performance over time
- Detect regressions in new features
- Ensure optimizations actually improve performance
- Validate memory usage stays within acceptable bounds

## Interpreting Results

### Benchmark Output Example

```
📂 File Size Performance Tests
------------------------------
Small file        0.1 KB      3 items   0.0023 sec    0.1 MB
Medium file      45.2 KB    100 items   0.0156 sec    2.3 MB
Large file      198.7 KB    150 items   0.0234 sec    5.1 MB
Huge file       512.3 KB   1000 items   0.0789 sec   12.7 MB

🔍 Search Performance Tests  
------------------------------
Key search             0.0012 sec (avg)   0.0009 sec (min)   0.0018 sec (max)
Value search           0.0034 sec (avg)   0.0028 sec (min)   0.0045 sec (max)
Combined search        0.0056 sec (avg)   0.0043 sec (min)   0.0078 sec (max)
```

### What to Watch For

- **Linear scaling**: Time/memory should scale reasonably with file size
- **Search consistency**: Search times should be relatively stable
- **Memory leaks**: No significant memory growth over iterations
- **Performance regressions**: Compare results over time

## Adding New Performance Tests

To add new performance tests:

1. Add test methods to `performance_test.rb`
2. Use the measurement helpers: `measure_memory_usage`, `measure_cpu_time`, etc.
3. Include `skip` conditions for optional tests
4. Add meaningful assertions for performance bounds
5. Document expected performance characteristics

## Dependencies

The performance tests have minimal dependencies:

- **Core tests**: Only standard Ruby libraries (Benchmark, ObjectSpace)
- **Memory profiler**: Requires `memory_profiler` gem (optional)
- **Test fixtures**: Generated automatically by `generate_fixtures.rb`

## Troubleshooting

### Common Issues

1. **Missing fixtures**: Run `rake performance:fixtures` first
2. **Memory profiler errors**: Install with `gem install memory_profiler`
3. **Slow tests**: Use environment variables to skip heavy tests
4. **Platform differences**: Performance varies by Ruby version and OS

### Environment Variables

- `PERFORMANCE=1` - Enable performance tests
- `STRESS_TEST=1` - Enable stress tests with massive datasets
- `RUBOCOP_PARALLEL=false` - Disable parallel RuboCop for cleaner output

## Contributing

When modifying Flatito code:

1. Run performance tests before and after changes
2. Document any expected performance impacts
3. Update performance bounds if needed
4. Add new tests for new features that might impact performance
