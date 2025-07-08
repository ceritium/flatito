#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to generate large YAML files for performance testing

require "yaml"

def generate_large_yaml(entries_count, file_path)
  data = {}

  entries_count.times do |i|
    section_name = "section_#{i}"
    data[section_name] = {
      "id" => i,
      "name" => "Item #{i} with a very long name that will test truncation and filtering performance",
      "description" => "This is a detailed description for item #{i} that contains multiple sentences and should be long enough to trigger truncation in most cases. It includes various keywords like performance, memory, cpu, benchmark, and testing to make search operations more realistic.",
      "metadata" => {
        "created_at" => "2025-01-#{(i % 28) + 1}T#{(i % 24).to_s.rjust(2, "0")}:#{(i % 60).to_s.rjust(2, "0")}:#{(i % 60).to_s.rjust(2, "0")}Z",
        "updated_at" => "2025-07-08T12:00:00Z",
        "version" => "1.#{i % 100}.#{i % 10}",
        "tags" => ["tag_#{i % 10}", "category_#{i % 5}", "type_#{i % 3}"],
        "properties" => {
          "enabled" => i.even?,
          "priority" => i % 5,
          "weight" => (i * 1.5).round(2),
          "configuration" => {
            "timeout" => 30_000 + (i * 100),
            "retries" => 3 + (i % 5),
            "buffer_size" => 1024 * ((i % 8) + 1),
            "compression" => i % 3 == 0,
            "encryption" => {
              "enabled" => i % 4 == 0,
              "algorithm" => ["aes256", "rsa", "ecdsa"][i % 3],
              "key_rotation_days" => 30 + (i % 60)
            }
          }
        }
      }
    }
  end

  File.write(file_path, YAML.dump(data))
  puts "Generated #{file_path} with #{entries_count} entries"
end

# Generate files of different sizes
generate_large_yaml(100, "test/fixtures/medium_file.yml")
generate_large_yaml(1000, "test/fixtures/huge_file.yml")
generate_large_yaml(5000, "test/fixtures/massive_file.yml")

puts "Performance test fixtures generated successfully!"
