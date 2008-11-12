#!/usr/bin/env ruby -wKU

# A script to organize my time lapse photo directory

require 'fileutils'

files = Dir.glob("/Users/dave/Pictures/motion_capture/*.png")
files.each do |file|
  date_string = File.mtime(file).strftime("%m_%d_%Y")
  FileUtils.mkdir("/Users/dave/Pictures/motion_capture/#{date_string}") unless File.exist?("/Users/dave/Pictures/motion_capture/#{date_string}")
  file_basename = File.basename(file)
  new_file_location = "/Users/dave/Pictures/motion_capture/#{date_string}/#{file_basename}"
  unless File.exist?(new_file_location)
    FileUtils.mv(file, new_file_location) 
    puts "Moved #{file_basename}"
  else
    puts "File already exists! #{file_basename}"
  end
end