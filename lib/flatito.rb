# frozen_string_literal: true

require "colorize"

require_relative "flatito/version"
require_relative "flatito/tree_iterator"
require_relative "flatito/flatten_yaml"
require_relative "flatito/finder"
require_relative "flatito/yaml_with_line_number"

module Flatito
  def self.search(paths, options)
    Finder.new(paths, options).call
  end
end
