# frozen_string_literal: true

require "test_helper"

class Flatito::FlattenYamlTest < Minitest::Test
  test "a json" do
    items = Flatito::FlattenYaml.new("test/fixtures/a.json").items

    assert_equal 5, items.size
    assert_equal "one", items[0].key
    assert_equal "One", items[0].value
    assert_equal 2, items[0].line
  end

  test "no nested" do
    items = Flatito::FlattenYaml.new("test/fixtures/no_nested.yml").items

    assert_equal 3, items.size
    assert_equal "one", items[0].key
    assert_equal "One", items[0].value
    assert_equal 1, items[0].line
  end

  test "nested" do
    items = Flatito::FlattenYaml.new("test/fixtures/nested.yml").items

    assert_equal 3, items.size
    assert_equal "nested1.one", items[0].key
    assert_equal "One", items[0].value
    assert_equal 2, items[0].line

    assert_equal "nested1.nested2.two", items[1].key
    assert_equal "Two", items[1].value
    assert_equal 4, items[1].line

    assert_equal "three", items[2].key
    assert_equal "Three", items[2].value
    assert_equal 5, items[2].line
  end

  test "with merging hashes" do
    items = Flatito::FlattenYaml.new("test/fixtures/merge.yml").items

    assert_equal 3, items.size

    assert_equal "default.adapter", items[0].key
    assert_equal "postgresql", items[0].value
    assert_equal 2, items[0].line

    assert_equal "development.database", items[1].key
    assert_equal "keepthissite_development", items[1].value
    assert_equal 4, items[1].line

    assert_equal "development.adapter", items[2].key
    assert_equal "postgresql", items[2].value
    assert_equal 2, items[2].line
  end

  test "multiline values" do
    items = Flatito::FlattenYaml.new("test/fixtures/multiline.yml").items

    assert_equal "en.long_message", items[0].key
    assert_equal 2, items[0].line

    assert_equal "en.a_sequence", items[1].key
    assert_equal 7, items[1].line
  end

  test "with ruby objects" do
    items = Flatito::FlattenYaml.new("test/fixtures/with_ruby_objects.yml").items

    assert_equal 3, items.size

    assert_equal "two", items[1].key
    assert_equal "[object: OpenStruct]", items[1].value
    assert_equal 2, items[1].line
  end
end
