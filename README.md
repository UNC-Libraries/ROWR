# ROWR: Really Old Website Resurrector

[![Build Status](https://travis-ci.org/UNC-Libraries/ROWR.svg?branch=master)](https://travis-ci.org/UNC-Libraries/ROWR) [![Gem Version](https://badge.fury.io/rb/rowr.svg)](https://badge.fury.io/rb/rowr)

It's basically link find/replace tool for a really old websites. ROWR will parse through your site files and look for any
broken links. When it finds one, it will prompt you to either replace, remove, 
ROWR takes a really old website, one that might be living on a cd flash drive for archival purposes, and allows you to clean up
any broken links.

## Installation

After installing ruby, add `gem 'rowr'` to your application's Gemfile or run the following from the command line:

    $ gem install rowr

## Usage

`rowr start` Start the script, will prompt you for information about the really old site.
While running, you can always prematurely stop the script with CMD+C or CTRL+C.

`rowr continue` Continue where you left off.
 
`rowr reset` Destroy all changes made and restart the process.  

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UNC-Libraries/ROWR/issues.

## License

The gem is available as open source under the terms of the [Apache License 2.0](http://www.apache.org/licenses/).

