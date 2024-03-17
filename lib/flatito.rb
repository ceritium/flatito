# frozen_string_literal: true

require "colorize"

require_relative "flatito/version"
require_relative "flatito/tree_iterator"
require_relative "flatito/flatten_yaml"
require_relative "flatito/finder"
require_relative "flatito/yaml_with_line_number"
require_relative "flatito/renderer"
require_relative "flatito/regex_from_search"
require_relative "flatito/print_items"
require_relative "flatito/config"

module Flatito
  class << self
    def search(paths, options = {})
      Finder.new(paths, options).call
    rescue Interrupt
      warn "\nInterrupted"
    end

    def flat_content(content, options = {})
      items = FlattenYaml.items_from_content(content)
      PrintItems.new(options[:search]).print(items)
    end
  end
end
