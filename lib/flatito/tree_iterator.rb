# frozen_string_literal: true

require "set"

module Flatito
  class TreeIterator
    include Enumerable

    attr_reader :base_path, :skip_hidden, :gitignore

    def initialize(base_path, options = {})
      @base_path = base_path
      @skip_hidden = options.fetch(:skip_hidden, true)
      @gitignore = options.fetch(:gitignore, true)
    end

    def each(&block)
      tree(Pathname.new(base_path), &block)
    end

    def tree(parent, &block)
      if parent.directory?
        return if parent.symlink?
        return if gitignore && ignored_dir?(parent)

        parent.each_child.each do |pathname|
          next if skip_hidden && pathname.basename.to_s[0] == "."

          tree(pathname, &block)
        end
      else
        yield(parent)
      end
    rescue Errno::ELOOP => e
      warn "Error reading #{parent}, #{e.message}"

      []
    end

    private

    def ignored_dir?(dir)
      expanded = File.expand_path(dir.to_s)
      ignored_dirs.any? { |ignored| expanded.start_with?(ignored) }
    end

    def ignored_dirs
      @ignored_dirs ||= build_ignored_dirs
    end

    def build_ignored_dirs
      base = File.expand_path(base_path)
      output = `git -C "#{base}" ls-files --others --ignored --exclude-standard --directory 2>/dev/null`
      return [] unless $?.success?

      output.lines.filter_map do |line|
        path = line.chomp
        File.join(base, path.delete_suffix("/")) if path.end_with?("/")
      end
    rescue Errno::ENOENT
      []
    end
  end
end
