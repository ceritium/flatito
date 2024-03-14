# frozen_string_literal: true

module Flatito
  class TreeIterator
    include Enumerable

    attr_reader :base_path, :skip_hidden

    def initialize(base_path, options = {})
      @base_path = base_path
      @skip_hidden = options[:skip_hidden] || true
    end

    def each(&block)
      tree(Pathname.new(base_path), &block)
    end

    def tree(parent, &block)
      if parent.directory?
        return if parent.symlink?

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
  end
end
