require 'rowr'

module Rowr

  class StateSaver

    def initialize(src_dir, filename)
      @src = src_dir
      @file = File.expand_path(File.join(@src, filename))
      @config = {}
      @cached = {}
      @scanned_files = []
    end

    attr_accessor :src
    attr_reader   :file
    attr_reader   :config
    attr_accessor :scanned_files
    attr_accessor :cached

    def config_file_exists?
      File.exist?(@file)
    end

    def save_state
      hashed = {
        config: @config,
        cached: @cached,
        scanned_files: scanned_files
      }
      File.open(@file, 'wb') { |f| f.write JSON.pretty_generate(hashed) }
    end

    def load_state
      file = JSON.parse(File.open(@file).read, symbolize_names: true)
      @config = file[:config]
      @cached = file[:cached]
      @scanned_files = file[:scanned_files]
    end

    def save_config(config)
      @config = config
      save_state
    end

  end
end