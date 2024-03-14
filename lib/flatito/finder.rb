# frozen_string_literal: true

require_relative "regex_from_search"

module Flatito
  class Finder
    include RegexFromSearch

    DEFAULT_EXTENSIONS = %w[json yml yaml].freeze

    attr_reader :paths, :search, :extensions, :options, :renderer

    def initialize(paths, options = {})
      @paths = paths
      @search = options[:search]
      @extensions = prepare_extensions(options[:extensions] || DEFAULT_EXTENSIONS)
      @options = options
      @renderer = Renderer.build(options)
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

      renderer.ending
    end

    private

    def flat_and_filter(pathname)
      items = FlattenYaml.new(pathname).items
      items = filter_by_search(items) if search

      return unless items.any?

      renderer.print_pathname(pathname)
      renderer.print_items(items)
    end

    def prepare_extensions(extensions)
      extensions.map do |ext|
        ext.start_with?(".") ? ext : ".#{ext}"
      end
    end

    def filter_by_search(items)
      items.select do |item|
        regex.match?(item.key)
      end
    end
  end
end
