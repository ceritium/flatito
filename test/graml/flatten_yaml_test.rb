# frozen_string_literal: true

require "test_helper"

class Flatito::FlattenYamlTest < Minitest::Test
  test "a json" do
    entries = Flatito::FlattenYaml.new("test/fixtures/a.json").entries

    assert_equal 5, entries.size
    assert_equal "one", entries[0].key
    assert_equal "One", entries[0].value
    assert_equal 2, entries[0].line
  end

  test "no nested" do
    entries = Flatito::FlattenYaml.new("test/fixtures/no_nested.yml").entries

    assert_equal 3, entries.size
    assert_equal "one", entries[0].key
    assert_equal "One", entries[0].value
    assert_equal 1, entries[0].line
  end

  test "nested" do
    entries = Flatito::FlattenYaml.new("test/fixtures/nested.yml").entries

    assert_equal 3, entries.size
    assert_equal "nested1.one", entries[0].key
    assert_equal "One", entries[0].value
    assert_equal 2, entries[0].line

    assert_equal "nested1.nested2.two", entries[1].key
    assert_equal "Two", entries[1].value
    assert_equal 4, entries[1].line

    assert_equal "three", entries[2].key
    assert_equal "Three", entries[2].value
    assert_equal 5, entries[2].line
  end

  test "with merging hashes" do
    entries = Flatito::FlattenYaml.new("test/fixtures/merge.yml").entries

    assert_equal 3, entries.size

    assert_equal "default.adapter", entries[0].key
    assert_equal "postgresql", entries[0].value
    assert_equal 2, entries[0].line

    assert_equal "development.database", entries[1].key
    assert_equal "keepthissite_development", entries[1].value
    assert_equal 4, entries[1].line

    assert_equal "development.adapter", entries[2].key
    assert_equal "postgresql", entries[2].value
    assert_equal 2, entries[2].line
  end

  test "multiline values" do
    entries = Flatito::FlattenYaml.new("test/fixtures/multiline.yml").entries

    assert_equal "en.long_message", entries[0].key
    assert_equal 2, entries[0].line

    assert_equal "en.a_sequence", entries[1].key
    assert_equal 7, entries[1].line
  end

  test "with ruby objects" do
    entries = Flatito::FlattenYaml.new("test/fixtures/with_ruby_objects.yml").entries

    assert_equal 3, entries.size

    assert_equal "two", entries[1].key
    assert_equal "[object: OpenStruct]", entries[1].value
    assert_equal 2, entries[1].line
  end
end
