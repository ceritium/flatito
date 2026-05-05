# frozen_string_literal: true

require "colorize"

require_relative "flatito/version"
require_relative "flatito/tree_iterator"
require_relative "flatito/flatten_yaml"
require_relative "flatito/json_scanner"
require_relative "flatito/finder"
require_relative "flatito/yaml_with_line_number"
require_relative "flatito/renderer"
require_relative "flatito/regex_from_search"
require_relative "flatito/print_items"
require_relative "flatito/config"
require_relative "flatito/diff_parser"
require_relative "flatito/diff_source"

module Flatito
  DEFAULT_DIFF_EXTENSIONS = %w[.json .yml .yaml].freeze

  class << self
    def search(paths, options = {})
      Finder.new(paths, options).call
    rescue Interrupt
      warn "\nInterrupted"
      nil
    end

    def flat_content(content, options = {})
      items = FlattenYaml.items_from_content(content)
      PrintItems.new(options[:search], options[:search_value], case_sensitive: options[:case_sensitive]).print(items) || false
    end

    def from_diff(diff_content, options = {})
      side = (options[:side] || :both).to_sym
      extensions = normalize_extensions(options[:extensions])
      printer = PrintItems.new(options[:search], options[:search_value],
                               case_sensitive: options[:case_sensitive])

      matched = false
      DiffParser.parse(diff_content).each do |file|
        next unless extension_match?(file.path, extensions)

        before, after = DiffSource.contents_for(file)
        items = collect_items(file, before, after, side)
        next if items.empty?

        matched = true if printer.print(items, file.path)
      end
      matched
    rescue Interrupt
      warn "\nInterrupted"
      nil
    end

    private

    def collect_items(file, before, after, side)
      items = []
      if %i[after both].include?(side) && after
        items.concat(filter_changed(FlattenYaml.items_from_content(after, pathname: file.path),
                                    file.added_lines, :add))
      end
      if %i[before both].include?(side) && before
        items.concat(filter_changed(FlattenYaml.items_from_content(before, pathname: file.path),
                                    file.removed_lines, :del))
      end
      items.sort_by { |item| [item.line, item.marker == :del ? 0 : 1] }
    end

    def filter_changed(items, line_set, marker)
      items.filter_map do |item|
        next unless line_set.include?(item.line)

        FlattenYaml::Item.new(key: item.key, value: item.value, line: item.line, marker: marker)
      end
    end

    def normalize_extensions(extensions)
      list = extensions || %w[json yml yaml]
      list.map { |ext| ext.start_with?(".") ? ext : ".#{ext}" }
    end

    def extension_match?(path, extensions)
      return false if path.nil?

      ext = ::File.extname(path)
      extensions.include?(ext)
    end
  end
end
