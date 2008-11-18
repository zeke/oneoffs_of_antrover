#!/usr/local/bin/ruby -wKU
# Creates an empty file with today's date

require 'rubygems'
require 'choice'

Choice.options do
  option :title do
    short '-t'
    long '--title=TITLE'
    desc "Set the title of the blog"
    default 'Untitled'
  end
end

file_name = "#{Time.now.strftime('%m_%d_%Y-%H:%M:%S')}-#{Choice.choices[:title].gsub(" ", "_")}.md"

exec("vim #{file_name}")