# frozen_string_literal: true

require "test_helper"

class Flatito::DiffParserTest < Minitest::Test
  test "detects diff content" do
    assert Flatito::DiffParser.diff?(File.read("test/fixtures/sample.diff"))
    assert Flatito::DiffParser.diff?("diff --git a/x b/x\nfoo")
    refute Flatito::DiffParser.diff?("nested1:\n  one: One\n")
    refute Flatito::DiffParser.diff?(nil)
    refute Flatito::DiffParser.diff?("")
  end

  test "parses a single-file diff" do
    files = Flatito::DiffParser.parse(File.read("test/fixtures/sample.diff"))

    assert_equal 1, files.size
    file = files.first

    assert_equal "test/fixtures/diff_sample.yml", file.path
    assert_equal "1111111", file.before_blob
    assert_equal "2222222", file.after_blob
    refute file.new_file
    refute file.deleted_file

    assert_equal Set.new([2, 5, 7]), file.added_lines
    assert_equal Set.new([2]), file.removed_lines
    assert_equal 1, file.hunks.size
    assert_equal 1, file.hunks.first.old_start
    assert_equal 1, file.hunks.first.new_start
  end

  test "parses a new file (--- /dev/null)" do
    diff = <<~DIFF
      diff --git a/new.yml b/new.yml
      new file mode 100644
      index 0000000..abcdef0
      --- /dev/null
      +++ b/new.yml
      @@ -0,0 +1,2 @@
      +alpha: 1
      +beta: 2
    DIFF

    files = Flatito::DiffParser.parse(diff)

    assert_equal 1, files.size
    file = files.first

    assert file.new_file
    assert_equal Set.new([1, 2]), file.added_lines
    assert_empty file.removed_lines
  end

  test "parses a deleted file (+++ /dev/null)" do
    diff = <<~DIFF
      diff --git a/gone.yml b/gone.yml
      deleted file mode 100644
      index abcdef0..0000000
      --- a/gone.yml
      +++ /dev/null
      @@ -1,2 +0,0 @@
      -alpha: 1
      -beta: 2
    DIFF

    files = Flatito::DiffParser.parse(diff)

    assert_equal 1, files.size
    file = files.first

    assert file.deleted_file
    assert_empty file.added_lines
    assert_equal Set.new([1, 2]), file.removed_lines
  end

  test "parses multiple files" do
    diff = <<~DIFF
      diff --git a/a.yml b/a.yml
      index 1111111..2222222 100644
      --- a/a.yml
      +++ b/a.yml
      @@ -1,1 +1,1 @@
      -x: 1
      +x: 2
      diff --git a/b.yml b/b.yml
      index 3333333..4444444 100644
      --- a/b.yml
      +++ b/b.yml
      @@ -1,1 +1,2 @@
       y: 1
      +z: 2
    DIFF

    files = Flatito::DiffParser.parse(diff)

    assert_equal 2, files.size
    assert_equal "a.yml", files[0].path
    assert_equal "b.yml", files[1].path
    assert_equal Set.new([1]), files[0].added_lines
    assert_equal Set.new([2]), files[1].added_lines
  end
end
