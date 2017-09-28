require 'rowr'

module Rowr

  class Prompter

    attr_reader     :source_directory
    attr_reader     :exts_to_use
    attr_reader     :old_host
    attr_reader     :new_base_path
    attr_accessor   :check_external_urls

    def initialize
      @prompt = TTY::Prompt.new
    end

    def source_directory=(value)
      dir = File.expand_path(value)
      @source_directory = dir if Dir.exist?(dir)
    end

    def old_host=(value)
      if value.to_s.empty?
        @old_host = false
      else
        @old_host = value.chomp('/').chomp('/').sub(%r{https?://}, '')
      end
    end

    def exts_to_use=(value)
      exts = []
      if value
        exts = value.split
        exts.map! { |e| e.start_with?('.') ? e[1..-1] : e } if exts.is_a?(Array)
      end
      exts = %w(htm html) + exts
      @exts_to_use = exts.uniq
    end

    def new_base_path=(value)
      clean = ''
      unless value.to_s.empty?
        clean = value.sub(%r{https?://(.*?)(/|$)}, '')
        clean = clean.split('/')
        clean = clean.reject(&:empty?)
        clean.shift if clean.first =~ /\./
        clean = clean.join('/')
      end
      @new_base_path = clean.to_s.empty? ? '/' : "/#{clean}/"
    end

    def dir_select
      @prompt.select('Where is this really old website?') do |menu|
        menu.default 1

        menu.choice "#{Dir.pwd} (The current dir)", 1
        menu.choice "Another directory?", 2
      end
    end

    def ask_for_other_source_directory
      dir = @prompt.ask('Please type in the path to that directory?') do |q|
        q.required true
      end
      unless Dir.exist?(File.expand_path(dir))
        @prompt.error("Sorry, #{dir} doesn't seem to exist")
        ask_for_other_source_directory
      end
      dir
    end

    def old_host?
      self.old_host = @prompt.ask('What was the old host? (e.g. www.google.com)')
    end

    def source_directory?
      self.source_directory = case dir_select
                              when 1
                                Dir.pwd
                              when 2
                                ask_for_other_source_directory
                              end
    end

    def additional_exts?
      @prompt.say('By default, I\'ll will scan any .html and .htm files.')
      self.exts_to_use  = @prompt.ask('Please list any other extensions, or hit Enter to skip')
    end

    def new_base_path?
      self.new_base_path = @prompt.ask('What will be the url of the resurrected site?')
    end

    def check_external_urls?
      self.check_external_urls = @prompt.select('If I find an link to an external site, what should I do?') do |menu|
        menu.default 1

        menu.choice 'Ask me about it', true
        menu.choice 'Skip it', false
      end
    end

    def generate_hash
      {
        source_directory: source_directory,
        exts_to_use: exts_to_use,
        old_host: old_host,
        new_base_path: new_base_path,
        check_external_urls: check_external_urls
      }
    end
  end
end