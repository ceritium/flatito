# frozen_string_literal: true

require_relative "utils"
module Flatito
  class FlattenYaml
    include Utils

    Item = Struct.new(:key, :value, :line, keyword_init: true)
    class << self
      def items_from_path(pathname)
        content = File.read(pathname)
        new(content, pathname: pathname).items
      end

      def items_from_content(content)
        new(content).items
      end
    end

    attr_reader :content, :pathname

    def initialize(content, pathname: nil)
      @content = content
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
