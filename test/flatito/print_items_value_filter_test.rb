# frozen_string_literal: true

require "test_helper"
require "flatito/print_items"
require "flatito/flatten_yaml"

class Flatito::PrintItemsValueFilterTest < Minitest::Test
  def items_from_fixture(fixture)
    Flatito::FlattenYaml.items_from_path("test/fixtures/#{fixture}")
  end

  test "filters by value with exact match" do
    items = items_from_fixture("no_nested.yml")
    filtered = Flatito::PrintItems.new(nil, "Two").filter_by_value(items)

    assert_equal 1, filtered.size
    assert_equal "two", filtered[0].key
    assert_equal "Two", filtered[0].value
  end

  test "filters by value with regex" do
    items = items_from_fixture("no_nested.yml")
    filtered = Flatito::PrintItems.new(nil, "T.*").filter_by_value(items)

    assert_equal 2, filtered.size
    assert_equal ["two", "three"], filtered.map(&:key)
  end

  test "filters by value with ruby object string" do
    items = items_from_fixture("with_ruby_objects.yml")
    filtered = Flatito::PrintItems.new(nil, "OpenStruct").filter_by_value(items)

    assert_equal 1, filtered.size
    assert_equal "two", filtered[0].key
    assert_equal "[object: OpenStruct]", filtered[0].value
  end
end
