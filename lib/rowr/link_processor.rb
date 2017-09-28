require 'rowr'

module Rowr

  class LinkProcessor

    attr_reader   :local_site_dir
    attr_reader   :old_domain
    attr_accessor :new_base_path
    attr_accessor :cached
    attr_reader   :link_to_check
    attr_accessor :containing_file
    attr_reader   :target_file

    def initialize(src_dir, old_domain = nil, new_base_path = nil, check_external_urls = true, cached = {})
      @printer = Rowr::Printer.new
      @prompt = TTY::Prompt.new(active_color: :cyan)
      @pastel = Pastel.new
      @local_site_dir = src_dir
      @old_domain = old_domain
      @new_base_path = new_base_path
      @check_external_urls = check_external_urls
      @cached = cached
    end

    ################################
    # Attributes
    ################################
    def link_to_check=(value)
      if external?(value)
        @link_to_check = value
      else
        value.sub!(old_url_regex, '') if @old_domain
        if value.start_with?('/')
          @link_to_check = value.sub(%r{(^/)}, '')
          @target_file = File.expand_path(File.join(@local_site_dir, @link_to_check))
        else
          @link_to_check = File.dirname(@containing_file).sub(@local_site_dir, '') + '/' + value
          @link_to_check.sub!(%r{(^/)}, '')
          @target_file = File.expand_path(File.join(File.dirname(@containing_file), value))
        end
      end
    end

    def old_url_regex
      %r{^(https?://|//)#{@old_domain}}i if @old_domain
    end

    ################################
    # Checkers
    ################################

    def external?(link)
      !old_uri?(link) && uri?(link) ? true : false
    end

    def old_uri?(link)
      if @old_domain
        link =~ old_url_regex
      else
        false
      end
    end

    def uri?(link)
      link =~ %r{^(https?:|//)}i
    end

    def in_cache?
      @cached.key?(link_key)
    end

    def response_code(link)
      begin
        res = Faraday.get link
        return res.status
      rescue
        return 0
      end
    end

    def trim_hash(file)
      file.sub(/#(.*?)$/,'')
    end

    def target_file_exists?
      File.exist?(trim_hash(@target_file))
    end

    def broken_external_link?
      res = response_code(@link_to_check)
      res > 399 || res < 200
    end

    def is_valid_replacement?(link)
      if uri?(link)
        res = response_code(link)
        res < 400 || res > 199
      else
        File.exist?(File.join(@local_site_dir, link))
      end
    end

    ################################
    # Misc
    ################################

    def link_key
      @link_to_check.to_sym
    end

    def add_to_cache(new_link)
      @cached[link_key] = new_link
    end

    def recommend_files
      Dir.glob("#{@local_site_dir}/**/{#{File.basename(@target_file)}}").map! do |f|
        f.sub(@local_site_dir,'')
      end
    end

    def prepend_new_base_path(link)
      check = @new_base_path[1..-1].chop
      new_link = link.sub(%r{^/?#{check}},'')
      new_link = new_link.sub(/^\//,'')
      @new_base_path + new_link
    end

    ################################
    # Processors
    ################################

    def process_link
      @new_base_path + @link_to_check if target_file_exists?
    end

    def process_broken_link
      return cached[link_key] if in_cache?
      replacement = nil
      @printer.print_broken_link_warning @containing_file, @link_to_check
      replacement = ask_recommended_files unless recommend_files.empty?
      replacement = ask_wtd unless replacement
      ask_to_cache(replacement)
      replacement
    end

    def process_external
      return nil unless @check_external_urls && broken_external_link?
      @printer.print_broken_link_warning @containing_file, @link_to_check
      replacement = ask_wtd
      ask_to_cache(replacement)
      replacement
    end

    def process(link, file = nil)
      @containing_file = file if file
      self.link_to_check = link

      if external?(@link_to_check)
        replacement = process_external
      else
        replacement = process_link
        replacement = process_broken_link unless replacement
      end
      replacement
    end

    ################################
    # Asks
    ################################

    def ask_recommended_files
      @printer.print_line ' I found some matching files ', '+', :blue
      recommended_files = recommend_files
      choice = @prompt.select(
          'Would you like to replace the broken link with any of the following?',
          recommended_files + ['None of these match'],
          per_page: 10
      )
      choice == 'None of these match' ? nil : prepend_new_base_path(choice)
    end

    def ask_to_cache(new_link)
      case new_link
      when nil
        message = "SKIP all instances of " + @pastel.green("#{@link_to_check}") + "?"
      when '#'
        message = "REMOVE all instances of " + @pastel.green("#{@link_to_check}") + "?"
      else
        message = "REPLACE all instances of " + @pastel.green("#{@link_to_check}") + " with " + @pastel.blue("#{new_link}") + "?"
      end
      add_to_cache(new_link) if @prompt.yes?(message)
    end

    def ask_wtd
      @printer.line_break 0
      wtd = @prompt.enum_select"What would you like to do?" do |menu|
        menu.default 1

        menu.choice 'Enter a new link', 1
        menu.choice 'Remove the link', 2
        menu.choice 'Skip', 3
      end

      case wtd
      when 1
        ask_new_link
      when 2
        '#'
      when 3
        nil
      end
    end

    def ask_new_link
      new_link = @prompt.ask('Enter the replacement:')
      unless is_valid_replacement?(new_link)
        if uri?(new_link)
          @prompt.error("Sorry, the url you've provided is not returning a 200 status code")
        else
          @prompt.error('Sorry, that file does not exist')
        end
        new_link = ask_new_link
      end

      if uri?(new_link)
        new_link
      else
        prepend_new_base_path(new_link)
      end
    end

  end
end
