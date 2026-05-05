# frozen_string_literal: true

require "test_helper"

class Flatito::FromDiffTest < Minitest::Test
  class CapturedIO < StringIO
    def tty?
      false
    end
  end

  def setup
    @stdout = CapturedIO.new
    Flatito::Config.stdout = @stdout
    Flatito::Config.prepare_with_options(no_color: true)
  end

  def diff
    File.read("test/fixtures/sample.diff")
  end

  test "from_diff side=both reports added and removed items" do
    matched = Flatito.from_diff(diff, no_color: true, side: :both)

    assert matched
    output = @stdout.string

    assert_includes output, "test/fixtures/diff_sample.yml"
    assert_includes output, "+ "
    assert_includes output, "- "
    assert_includes output, "nested1.one"
    assert_includes output, "nested1.nested2.extra"
    assert_includes output, "four"
  end

  test "from_diff side=after only reports added items" do
    matched = Flatito.from_diff(diff, no_color: true, side: :after)

    assert matched
    output = @stdout.string

    assert_includes output, "+ "
    refute_includes output, "- "
  end

  test "from_diff side=before only reports removed items" do
    matched = Flatito.from_diff(diff, no_color: true, side: :before)

    assert matched
    output = @stdout.string

    assert_includes output, "- "
    refute_includes output, "+ "
  end

  test "from_diff respects search key filter" do
    matched = Flatito.from_diff(diff, no_color: true, side: :both, search: "extra")

    assert matched
    output = @stdout.string

    assert_includes output, "nested1.nested2.extra"
    refute_includes output, "four"
  end

  test "from_diff returns false when no item matches search" do
    matched = Flatito.from_diff(diff, no_color: true, side: :both, search: "no-such-key")

    refute matched
  end

  test "from_diff filters by extension" do
    other_diff = <<~DIFF
      diff --git a/foo.txt b/foo.txt
      index 1111111..2222222 100644
      --- a/foo.txt
      +++ b/foo.txt
      @@ -1,1 +1,1 @@
      -hello
      +world
    DIFF

    refute Flatito.from_diff(other_diff, no_color: true)
  end
end
