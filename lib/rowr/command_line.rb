require 'rowr'
require 'tty-prompt'

module Rowr

  class CommandLine < Thor

    desc 'start',
         'resurrect a really old website'

    def start
      rowr = Rowr::Resurrector.new
      rowr.start
    end

    desc 'continue',
         'continue resurrecting'

    def continue
      rowr = Rowr::Resurrector.new
      rowr.continue
    end

    desc 'reset',
         'restart the really old website resurrection'

    def reset
      rowr = Rowr::Resurrector.new
      rowr.reset
    end

    desc 'test <file>',
         'test the resurrector on a single file'

    def test(file)
      return unless File.exist? File.expand_path(file)

      f = File.expand_path(file)
      rowr = Rowr::Resurrector.new

      rowr.options.source_directory = File.dirname(f)
      rowr.prompt_user_for_option 'old_host?'
      rowr.prompt_user_for_option 'new_base_path?'
      rowr.prompt_user_for_option 'check_external_urls?'

      rowr.init_link_processor

      rowr.link_processor.containing_file = f

      text = File.read(f)
      unless text.valid_encoding?
        text = text.encode('UTF-16be', :invalid=>:replace, :replace=>'&nbsp;').encode('UTF-8')
      end
      text = rowr.clean_no_quotes(text)
      rowr.check_urls(text)

    end

  end

end