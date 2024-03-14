# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "flatito"

require "minitest/autorun"
require "support/test_macro"

Minitest::Test.class_eval do
  extend TestMacro
end
