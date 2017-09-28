require 'rowr'

module Rowr

  class Resurrector

    attr_accessor :link_processor
    attr_accessor :options

    def initialize
      @printer = Rowr::Printer.new
      @option_getter = Rowr::Prompter.new
      @state = Rowr::StateSaver.new Dir.pwd, 'rowr_state.json'
      @prompt = TTY::Prompt.new
      @config = {}
    end

    def init_link_processor(cached = {})
      @link_processor = Rowr::LinkProcessor.new(
        @config[:source_directory],
        @config[:old_host],
        @config[:new_base_path],
        @config[:check_external_urls],
        cached
      )
    end

    def files_with_exts(exts)
      regex = /\.(#{exts.join('|')})$/i
      Dir.glob(File.join(@config[:source_directory], '**', '*')).grep(regex).reject { |f| !File.file?(f) }
    end

    def clean_no_quotes(file_contents)
      find = %r{(?<=href=|src=|background=)(?!['"])(?<content>[^> ]*)}mi
      file_contents.gsub(find) do |match|
        "\"#{$~[:content]}\""
      end
    end

    def check_urls(file_contents)
      find = %r{(?<=(?<=href=|src=|url\(|background=)['"])(?!(mailto:|#))(?<content>.*?)(?=["'])}mi
      file_contents.gsub(find) do |match|
        content = $~[:content].strip
        replacement = @link_processor.process(content)
        replacement.nil? ? content : replacement
      end
    end

    def prompt_user_for_option(option)
      @option_getter.send(option.to_sym)
    end

    def gather_options
      @printer.line_break 0
      prompt_user_for_option 'old_host?'
      @printer.line_break 0
      prompt_user_for_option 'new_base_path?'
      @printer.line_break 0
      prompt_user_for_option 'additional_exts?'
      @printer.line_break 0
      prompt_user_for_option 'check_external_urls?'
      @printer.line_break 0
    end

    def load_state
      @state.load_state
      @config = @state.config
    end

    def continue
      unless @state.config_file_exists?
        loop do
          @printer.print_line " I can't find a rowr save file in this directory... "
          prompt_user_for_option 'source_directory?'
          @state.src = @option_getter.source_directory
          break if @state.config_file_exists?
        end
      end
      load_state
      run
    end

    def start
      @printer.print_intro
      @printer.print_line " Before we start, I've got some questions "
      prompt_user_for_option 'source_directory?'
      @state.src = @option_getter.source_directory
      if @state.config_file_exists?
        @prompt.say("I've found a rowr save file.")
        if @prompt.select('Would you like to continue or reset?', %w(Continue Reset)) == 'Continue'
          continue
        end
      end
      prep
    end

    def reset
      zipper = Rowr::Zipper.new Dir.pwd
      if zipper.backup_file_exists?
        @option_getter.source_directory = Dir.pwd
      else
        loop do
          @prompt.warn("I can't find a rowr backup file in this directory. Where is the old site?")
          prompt_user_for_option 'source_directory?'
          zipper.src = @option_getter.source_directory
          break if zipper.backup_file_exists?
        end
      end
      zipper.restore
      prep
    end

    def prep
      gather_options
      @config = @option_getter.generate_hash
      @state.save_config(@config)
      @printer.print_line " Let's get started "
      @printer.line_break 0.5
      run
    end

    def run
      # Backup
      zipper = Rowr::Zipper.new @config[:source_directory]
      zipper.backup

      # Prep the link processor
      init_link_processor(@state.cached)
      files = files_with_exts(@config[:exts_to_use])
      count = files.length

      # Print the run intro
      @printer.print_line
      @printer.print_line " I've found #{count} files to scan "
      @printer.print_line
      @printer.line_break 0.5
      unless @state.scanned_files.empty?
        count -= @state.scanned_files.length
        @printer.print_line(
          " Skipping #{@state.scanned_files.length} files, previously scanned.",
          '!',
          'red'
        )
        @printer.line_break 0.5
      end

      files.each do |f|
        # Skip any previously scanned files
        next if @state.scanned_files.include?(f)

        # Print the intro
        @printer.print_file_header f
        @printer.line_break 0

        # Run @link_processor over all matching links
        text = File.read(f)
        @link_processor.containing_file = f
        unless text.valid_encoding?
          text = text.encode('UTF-16be', invalid: :replace, replace: '&nbsp;').encode('UTF-8')
        end
        text = clean_no_quotes(text)
        text = check_urls(text)
        File.open(f, 'w') { |file| file.puts text }
        count -= 1

        ## Update the state
        @state.scanned_files << f
        @state.cached = @link_processor.cached
        @state.save_state

        # Print count, onto next file
        @printer.line_break 0
        @printer.print_line " #{count} files left ", '*', 'cyan'
        @printer.line_break 0
      end

      @printer.print_outro
    end
  end
end