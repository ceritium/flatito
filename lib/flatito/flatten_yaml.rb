# frozen_string_literal: true

module Flatito
  class FlattenYaml
    Item = Struct.new(:key, :value, :line, keyword_init: true)
    class << self
      def items_from_path(pathname)
        content = File.read(pathname)
        new(content, pathname: pathname).items
      end

      def items_from_content(content, pathname: nil)
        new(content, pathname: pathname).items
      end
    end

    attr_reader :content, :pathname

    def initialize(content, pathname: nil)
      @content = content
      @pathname = pathname
    end

    def items
      with_line_numbers.filter_map do |line|
        flatten_hash(line) if line.is_a?(Hash)
      end.flatten
    end

    def flatten_hash(hash, prefix = nil)
      hash.filter_map do |key, value|
        next unless value.is_a?(YAMLWithLineNumber::ValueWithLineNumbers)

        full_key = prefix ? "#{prefix}.#{key}" : key
        if value.value.is_a?(Hash)
          flatten_hash(value.value, full_key)
        else
          Item.new(key: full_key, value: value.value.to_s, line: value.line)
        end
      end
    end

    def with_line_numbers
      handler = YAMLWithLineNumber::TreeBuilder.new
      handler.parser = Psych::Parser.new(handler)

      handler.parser.parse(content)
      YAMLWithLineNumber::VisitorsToRuby.create.accept(handler.root)
    rescue Psych::SyntaxError
      warn "Invalid format #{pathname}"
      []
    rescue StandardError
      warn "Error parsing #{pathname}"
      []
    end
  end
end
