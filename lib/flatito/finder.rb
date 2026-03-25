# frozen_string_literal: true

require_relative "regex_from_search"

module Flatito
  class Finder
    include RegexFromSearch

    DEFAULT_EXTENSIONS = %w[json yml yaml].freeze

    attr_reader :paths, :search, :search_value, :case_sensitive, :extensions, :options, :print_items

    def initialize(paths, options = {})
      @paths = paths
      @search = options[:search]
      @search_value = options[:search_value]
      @case_sensitive = options[:case_sensitive]
      @extensions = prepare_extensions(options[:extensions] || DEFAULT_EXTENSIONS)
      @options = options
      @print_items = PrintItems.new(search, search_value, case_sensitive: case_sensitive)
    end

    def call
      renderer.prepare

      paths.each do |path|
        TreeIterator.new(path, options).each do |pathname|
          renderer.print_file_progress(pathname)

          if extensions.include?(pathname.extname)
            flat_and_filter(pathname)
          end
        end
      end
    ensure
      renderer.ending
    end

    private

    def renderer
      Config.renderer
    end

    def flat_and_filter(pathname)
      content = File.read(pathname)
      return unless content_may_match?(content)

      items = FlattenYaml.items_from_content(content, pathname: pathname)
      print_items.print(items, pathname)
    end

    def content_may_match?(content)
      return true if search.nil? && search_value.nil?

      (!search || key_parts_match?(content)) &&
        (!search_value || value_regex.match?(content))
    end

    def key_parts_match?(content)
      key_part_regexes.all? { |part| part.match?(content) }
    end

    def key_part_regexes
      @key_part_regexes ||= search.split(".").map do |part|
        Regexp.new(part, case_sensitive ? nil : Regexp::IGNORECASE)
      end
    end

    def prepare_extensions(extensions)
      extensions.map do |ext|
        ext.start_with?(".") ? ext : ".#{ext}"
      end
    end
  end
end
