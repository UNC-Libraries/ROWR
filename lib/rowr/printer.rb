require 'rowr'

module Rowr

  class Printer

    def initialize(line_length = 50)
      @pastel = Pastel.new
      @line_length = line_length
    end

    def line(text = '', char = '~')
      message = text.to_s
      return message if too_long?(message)

      waves = char * ((@line_length - message.length) / 2).ceil
      output = "#{waves}#{message}#{waves}"
      output + (char * (50 - output.length))
    end

    def too_long?(string)
      string.length > @line_length
    end

    def line_break(duration)
      puts "\n"
      sleep(duration)
    end

    def print_line(message = nil, char = '~', color = 'green')
      puts @pastel.send(color.to_sym, line(message, char))
    end

    def print_intro
      print_line
      print_line ' ROWR! '
      print_line
      line_break 1
    end

    def print_outro
      print_line
      print_line " You're all done! "
      print_line
      print_line ' rowr... '
      print_line
    end

    def print_broken_link_warning(file, link)
      line_break 0
      print_line '', '!', 'yellow'
      print_line ' Broken Link ', '!', 'yellow'
      puts @pastel.magenta.bold('File: ', @pastel.red(file))
      puts @pastel.magenta.bold('Link: ', @pastel.green(link))
    end

    def print_file_header(file)
      print_line ' FILE ', '*', 'cyan'
      print_line " #{file} ", '*', 'cyan'
      print_line '', '*', 'cyan'
    end

  end
end