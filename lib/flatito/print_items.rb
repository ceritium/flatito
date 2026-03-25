# frozen_string_literal: true

module Flatito
  class PrintItems
    include RegexFromSearch

    attr_reader :search, :search_value, :case_sensitive

    def initialize(search, search_value = nil, case_sensitive: false)
      @search = search
      @search_value = search_value
      @case_sensitive = case_sensitive
    end

    def print(items, pathname = nil)
      items = filter_by_search(items) if search
      items = filter_by_value(items) if search_value
      return unless items.any?

      renderer.print_pathname(pathname) if pathname
      renderer.print_items(items)
    end

    def filter_by_search(items)
      items.select do |item|
        regex.match?(item.key)
      end
    end

    def filter_by_value(items)
      items.select do |item|
        value_regex.match?(item.value)
      end
    end

    private

    def value_regex
      @value_regex ||= Regexp.new(search_value, case_sensitive ? nil : Regexp::IGNORECASE)
    end

    def renderer
      Config.renderer
    end
  end
end
