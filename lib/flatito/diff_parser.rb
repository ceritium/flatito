# frozen_string_literal: true

require "set"

module Flatito
  class DiffParser
    File = Struct.new(
      :path, :before_path, :after_path,
      :before_blob, :after_blob,
      :hunks, :added_lines, :removed_lines,
      :new_file, :deleted_file,
      keyword_init: true
    )

    Hunk = Struct.new(:old_start, :old_count, :new_start, :new_count, :lines, keyword_init: true)

    HUNK_HEADER = /\A@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@/
    INDEX_LINE = /\Aindex ([0-9a-f]+)\.\.([0-9a-f]+)/

    def self.parse(content)
      new(content).parse
    end

    def self.diff?(content)
      return false if content.nil? || content.empty?

      head = content.byteslice(0, 4096).to_s
      head.start_with?("diff --git ") ||
        (head.include?("\n--- ") && head.include?("\n+++ ") && head.include?("\n@@ "))
    end

    def initialize(content)
      @lines = content.lines
      @i = 0
    end

    def parse
      files = []
      current = nil

      while @i < @lines.size
        line = @lines[@i]

        if line.start_with?("diff --git ")
          files << current if current && !current.path.nil?
          current = new_file_record
          @i += 1
          next
        end

        unless current
          @i += 1
          next
        end

        if (m = line.match(INDEX_LINE))
          current.before_blob = m[1]
          current.after_blob = m[2]
        elsif line.start_with?("new file mode")
          current.new_file = true
        elsif line.start_with?("deleted file mode")
          current.deleted_file = true
        elsif line.start_with?("--- ")
          handle_minus_header(line, current)
        elsif line.start_with?("+++ ")
          handle_plus_header(line, current)
        elsif (m = line.match(HUNK_HEADER))
          @i += 1
          consume_hunk(current, m)
          next
        end

        @i += 1
      end

      files << current if current && !current.path.nil?
      files
    end

    private

    def new_file_record
      File.new(
        hunks: [],
        added_lines: Set.new,
        removed_lines: Set.new,
        new_file: false,
        deleted_file: false
      )
    end

    DEV_NULL = "/dev/null" # rubocop:disable Style/FileNull
    private_constant :DEV_NULL

    def handle_minus_header(line, current)
      raw = line[4..].to_s.chomp
      path = raw.split("\t", 2).first.to_s
      if path == DEV_NULL
        current.new_file = true
      elsif path.start_with?("a/")
        current.before_path = path[2..]
      else
        current.before_path = path
      end
    end

    def handle_plus_header(line, current)
      raw = line[4..].to_s.chomp
      path = raw.split("\t", 2).first.to_s
      if path == DEV_NULL
        current.deleted_file = true
      elsif path.start_with?("b/")
        current.after_path = path[2..]
      else
        current.after_path = path
      end
      current.path ||= current.after_path || current.before_path
    end

    def consume_hunk(current, header_match)
      old_ln = header_match[1].to_i
      new_ln = header_match[3].to_i
      hunk = Hunk.new(
        old_start: old_ln,
        old_count: (header_match[2] || "1").to_i,
        new_start: new_ln,
        new_count: (header_match[4] || "1").to_i,
        lines: []
      )

      while @i < @lines.size
        hl = @lines[@i]
        break if hl.start_with?("diff --git ", "@@ ", "--- ", "+++ ")

        if hl.start_with?("+")
          hunk.lines << { kind: :add, text: hl[1..].to_s }
          current.added_lines << new_ln
          new_ln += 1
        elsif hl.start_with?("-")
          hunk.lines << { kind: :del, text: hl[1..].to_s }
          current.removed_lines << old_ln
          old_ln += 1
        elsif hl.start_with?(" ")
          hunk.lines << { kind: :context, text: hl[1..].to_s }
          old_ln += 1
          new_ln += 1
        elsif hl.start_with?("\\")
          # "\ No newline at end of file" — ignore
        elsif hl == "\n" || hl.empty?
          hunk.lines << { kind: :context, text: hl }
          old_ln += 1
          new_ln += 1
        else
          break
        end

        @i += 1
      end

      current.hunks << hunk
    end
  end
end
