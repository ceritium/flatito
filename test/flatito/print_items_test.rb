# frozen_string_literal: true

require "test_helper"

class Flatito::PrintItemsTest < Minitest::Test
  def setup
    @items = Flatito::FlattenYaml.items_from_path("test/fixtures/nested.yml")
    Flatito::Config.prepare_with_options({})
  end

  test "filter by key" do
    print_items = Flatito::PrintItems.new("nested1")
    filtered = print_items.filter_by_search(@items)

    assert_equal 2, filtered.size
    assert_equal "nested1.one", filtered[0].key
    assert_equal "nested1.nested2.two", filtered[1].key
  end

  test "filter by value" do
    print_items = Flatito::PrintItems.new(nil, "One")
    filtered = print_items.filter_by_value(@items)

    assert_equal 1, filtered.size
    assert_equal "nested1.one", filtered[0].key
    assert_equal "One", filtered[0].value
  end

  test "filter by value with regex" do
    print_items = Flatito::PrintItems.new(nil, "T(wo|hree)")
    filtered = print_items.filter_by_value(@items)

    assert_equal 2, filtered.size
    assert_equal "Two", filtered[0].value
    assert_equal "Three", filtered[1].value
  end

  test "filter by key and value" do
    print_items = Flatito::PrintItems.new("nested1", "Two")
    filtered = print_items.filter_by_search(@items)
    filtered = print_items.filter_by_value(filtered)

    assert_equal 1, filtered.size
    assert_equal "nested1.nested2.two", filtered[0].key
    assert_equal "Two", filtered[0].value
  end

  test "filter by value with no matches" do
    print_items = Flatito::PrintItems.new(nil, "nonexistent")
    filtered = print_items.filter_by_value(@items)

    assert_empty filtered
  end

  test "filter by key ignore case by default" do
    print_items = Flatito::PrintItems.new("NESTED1")
    filtered = print_items.filter_by_search(@items)

    assert_equal 2, filtered.size
    assert_equal "nested1.one", filtered[0].key
  end

  test "filter by key case sensitive" do
    print_items = Flatito::PrintItems.new("NESTED1", nil, case_sensitive: true)
    filtered = print_items.filter_by_search(@items)

    assert_empty filtered
  end

  test "filter by value ignore case by default" do
    print_items = Flatito::PrintItems.new(nil, "one")
    filtered = print_items.filter_by_value(@items)

    assert_equal 1, filtered.size
    assert_equal "One", filtered[0].value
  end

  test "filter by value case sensitive" do
    print_items = Flatito::PrintItems.new(nil, "one", case_sensitive: true)
    filtered = print_items.filter_by_value(@items)

    assert_empty filtered
  end
end
