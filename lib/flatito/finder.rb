# frozen_string_literal: true

require "set"
require_relative "regex_from_search"

module Flatito
  class Finder
    include RegexFromSearch

    DEFAULT_EXTENSIONS = %w[json yml yaml].freeze

    attr_reader :paths, :search, :search_value, :case_sensitive, :extensions, :options, :print_items

    def initialize(paths, options = {})
      @paths = paths
      @search = options[:search]
      @search_value = options[:search_value]
      @case_sensitive = options[:case_sensitive]
      @extensions = prepare_extensions(options[:extensions] || DEFAULT_EXTENSIONS)
      @options = options
      @print_items = PrintItems.new(search, search_value, case_sensitive: case_sensitive)
    end

    def call
      renderer.prepare

      paths.each do |path|
        TreeIterator.new(path, options).each do |pathname|
          renderer.print_file_progress(pathname)

          if extensions.include?(pathname.extname)
            flat_and_filter(pathname)
          end
        end
      end
    ensure
      renderer.ending
    end

    private

    def renderer
      Config.renderer
    end

    def flat_and_filter(pathname)
      return if git_candidates && !git_candidates.include?(File.expand_path(pathname.to_s))

      content = File.read(pathname)
      return unless git_candidates || content_may_match?(content)

      items = FlattenYaml.items_from_content(content, pathname: pathname)
      print_items.print(items, pathname)
    end

    def git_candidates
      return @git_candidates if defined?(@git_candidates)

      @git_candidates = build_git_candidates
    end

    def build_git_candidates
      return nil if search.nil? && search_value.nil?

      patterns = []
      patterns.concat(search.split(".")) if search
      patterns << search_value if search_value

      candidates = Set.new
      paths.each do |path|
        dir = File.directory?(path) ? path : File.dirname(path)
        files = git_grep(dir, patterns)
        return nil if files.nil?

        candidates.merge(files)
      end
      candidates
    end

    def git_grep(dir, patterns)
      expanded_dir = File.expand_path(dir)
      args = ["git", "-C", expanded_dir, "grep", "--untracked", "-l"]
      args << "-i" unless case_sensitive
      args << "--all-match" if patterns.size > 1
      patterns.each { |p| args.push("-e", p) }
      args.push("--", ".")

      output = IO.popen(args, err: File::NULL, &:read)
      return nil unless [0, 1].include?($?.exitstatus)

      Set.new(output.lines.map { |f| File.expand_path(f.chomp, expanded_dir) })
    rescue Errno::ENOENT
      nil
    end

    def content_may_match?(content)
      return true if search.nil? && search_value.nil?

      (!search || key_parts_match?(content)) &&
        (!search_value || value_regex.match?(content))
    end

    def key_parts_match?(content)
      key_part_regexes.all? { |part| part.match?(content) }
    end

    def key_part_regexes
      @key_part_regexes ||= search.split(".").map do |part|
        Regexp.new(part, case_sensitive ? nil : Regexp::IGNORECASE)
      end
    end

    def prepare_extensions(extensions)
      extensions.map do |ext|
        ext.start_with?(".") ? ext : ".#{ext}"
      end
    end
  end
end
