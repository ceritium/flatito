# frozen_string_literal: true

require "json"

module Flatito
  class JsonScanner
    def self.scan(content)
      new(content).items
    end

    attr_reader :content

    def initialize(content)
      @content = content
      @line_index = nil
    end

    def items
      hash = JSON.parse(content)
      flatten(hash)
    rescue JSON::ParserError
      nil
    end

    private

    def flatten(hash, prefix = nil)
      hash.flat_map do |key, value|
        full_key = prefix ? "#{prefix}.#{key}" : key
        if value.is_a?(Hash)
          flatten(value, full_key)
        else
          line = find_line(key)
          FlattenYaml::Item.new(key: full_key, value: value.to_s, line: line)
        end
      end
    end

    def find_line(key)
      line_index[key] || 0
    end

    def line_index
      @line_index ||= build_line_index
    end

    def build_line_index
      index = {}
      content.each_line.with_index(1) do |line, num|
        if (match = line.match(/"([^"]+)"\s*:/))
          index[match[1]] ||= num
        end
      end
      index
    end
  end
end
