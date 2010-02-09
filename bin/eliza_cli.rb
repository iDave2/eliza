#!/usr/bin/ruby
#
# == Synopsis
#
# eliza_cli - eliza command line interface
#
# == Usage
#
# eliza_cli [options]
#
# -h, --help:
#    show help
#
# -i f, --input f:
#    read input from file f rather than command line
#
# --script s, -s s:
#    use script in file s; default script is named 'script'
#

my_bin    = File.dirname(__FILE__)
my_lib    = my_bin + '/../lib'
my_script = my_lib + '/eliza/scripts/original.txt'

$: << my_lib

require 'eliza'
require 'getoptlong'
#require 'rdoc/usage' # missing in 1.9? how annoying...

# set defaults
inputStream = STDIN
outputStream = STDOUT
outputStream.sync = true
scriptName = my_script

opts = GetoptLong.new(
                      [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
[ '--input', '-i', GetoptLong::REQUIRED_ARGUMENT ],
[ '--script', '-s', GetoptLong::REQUIRED_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
  when '--help'
    puts "usage: eliza_cli [--input=s] [--script=s]"
    exit 1
  when '--input'
    inputStream = File.new(arg)
  when '--script'
    scriptName = arg
  else
    puts "error: unexpected input, try --help"
    exit 1
  end
end

Eliza.new(scriptName, inputStream, outputStream).run
