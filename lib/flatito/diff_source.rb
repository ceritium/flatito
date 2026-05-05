# frozen_string_literal: true

require "English"

module Flatito
  module DiffSource
    NULL_BLOB = "0000000"

    module_function

    def contents_for(file)
      before = file.new_file ? nil : load_side(file.before_blob, file.before_path, file)
      after = file.deleted_file ? nil : load_side(file.after_blob, file.after_path, file, after_side: true)
      [before, after]
    end

    def load_side(blob, path, file, after_side: false)
      content = blob_content(blob)
      return content if content

      content = working_tree_content(path) if after_side
      return content if content

      reconstruct_from_hunks(file, after_side: after_side)
    end

    def blob_content(blob)
      return nil if blob.nil? || blob.start_with?(NULL_BLOB)

      output = IO.popen(["git", "cat-file", "-p", blob], err: File::NULL, &:read)
      return nil unless $CHILD_STATUS&.exitstatus&.zero?

      output
    rescue Errno::ENOENT
      nil
    end

    def working_tree_content(path)
      return nil if path.nil? || path.empty?
      return nil unless ::File.file?(path)

      ::File.read(path)
    rescue StandardError
      nil
    end

    def reconstruct_from_hunks(file, after_side:)
      lines = []
      file.hunks.each do |hunk|
        target_line = after_side ? hunk.new_start : hunk.old_start
        pad_until(lines, target_line - 1)
        hunk.lines.each do |entry|
          case entry[:kind]
          when :context
            lines << entry[:text]
          when :add
            lines << entry[:text] if after_side
          when :del
            lines << entry[:text] unless after_side
          end
        end
      end
      lines.join
    end

    def pad_until(lines, target_index)
      lines << "\n" while lines.size < target_index
    end
  end
end
