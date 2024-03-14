# frozen_string_literal: true

require "test_helper"

class TestFlatito < Minitest::Test
  test "that it has a version number" do
    refute_nil ::Flatito::VERSION
  end
end
