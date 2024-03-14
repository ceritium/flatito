# frozen_string_literal: true

module Flatito
  class FlattenYaml
    Item = Struct.new(:key, :value, :line, keyword_init: true)
    def initialize(pathname)
      @pathname = pathname
    end

    def items 
      with_line_numbers.compact.flat_map do |line|
        flatten_hash(line) if line.is_a?(Hash)
      end.compact
    end

    def flatten_hash(hash, prefix = nil)
      hash.flat_map do |key, value|
        if value.is_a?(YAMLWithLineNumber::ValueWithLineNumbers)
          if value.value.is_a?(Hash)
            flatten_hash(value.value, [prefix, key].compact.join("."))
          else
            Item.new(key: [prefix, key].compact.join("."), value: truncate(value.value.to_s), line: value.line)
          end
        end
      end
    rescue StandardError => e
      warn "Error parsing #{@pathname}, #{e.message}"
    end

    def with_line_numbers
      handler = YAMLWithLineNumber::TreeBuilder.new
      handler.parser = Psych::Parser.new(handler)

      handler.parser.parse(File.read(@pathname))
      YAMLWithLineNumber::VisitorsToRuby.create.accept(handler.root)
    rescue Psych::SyntaxError
      warn "Invalid YAML #{@pathname}"

      []
    rescue StandardError => e
      warn "Error parsing #{@pathname}, #{e.message}"

      []
    end

    def truncate(string, max = 50)
      string.length > max ? "#{string[0...max]}..." : string
    end
  end
end
