# frozen_string_literal: true

module Flatito
  class PrintItems
    include RegexFromSearch
    attr_reader :search

    def initialize(search)
      @search = search
    end

    def print(items, pathname = nil)
      items = filter_by_search(items) if search
      return unless items.any?

      renderer.print_pathname(pathname) if pathname
      renderer.print_items(items)
    end

    def filter_by_search(items)
      items.select do |item|
        regex.match?(item.key)
      end
    end

    def renderer
      Config.renderer
    end
  end
end
