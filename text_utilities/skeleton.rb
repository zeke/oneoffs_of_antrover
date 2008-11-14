#!/usr/local/bin/ruby -wKU

# Creates an empty file titled like so: '10_24_1980-12:04:43-Untitled'
# The first argument will be used as the title, otherwise 'Untitled' will be used.
# Opens vim with the named file.

title = ARGV[0] || 'Untitled'
file_name = "#{Time.now.strftime('%m_%d_%Y-%H:%M:%S')}-#{title}.txt"
exec("vim #{file_name}")
