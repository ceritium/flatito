# frozen_string_literal: true

require_relative "regex_from_search"

module Flatito
  class Finder
    include RegexFromSearch

    DEFAULT_EXTENSIONS = %w[json yml yaml].freeze

    attr_reader :paths, :search, :search_value, :extensions, :options, :print_items

    def initialize(paths, options = {})
      @paths = paths
      @search = options[:search]
      @search_value = options[:search_value]
      @extensions = prepare_extensions(options[:extensions] || DEFAULT_EXTENSIONS)
      @options = options
      @print_items = PrintItems.new(search, search_value)
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
      items = FlattenYaml.items_from_path(pathname)
      print_items.print(items, pathname)
    end

    def prepare_extensions(extensions)
      extensions.map do |ext|
        ext.start_with?(".") ? ext : ".#{ext}"
      end
    end
  end
end
