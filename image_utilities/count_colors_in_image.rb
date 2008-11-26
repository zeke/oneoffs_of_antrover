#!/usr/bin/env ruby -wKU

# Extract the top 10 color hex codes from an image. 
# The output will look like this:

# 99.4373401534527 - 155520 - black
# 0.482736572890026 - 755 - #010101
# 0.0581841432225064 - 91 - #020202
# 0.0153452685421995 - 24 - gray1
# 0.00639386189258312 - 10 - #040404
# Total pixels is: 156400

# First column is the count, and the second column is the hex color.

require 'rubygems'
require 'RMagick'

# Open the image
# pic = Magick::ImageList.new("/Users/dave/Desktop/tiff_and_i_cooking.png")
# pic = Magick::ImageList.new("/Users/dave/Desktop/3047241275_a94b5bd10a_o.jpg")
pic = Magick::ImageList.new("/Users/dave/Desktop/black.jpg")

# Sort the histogram based on the count of the hex color
sorted = pic.color_histogram.sort {|a,b| b[1] <=> a[1]}
total_pixels = 0
sorted.each do |value|
  total_pixels += value[1]
end

color_map = []

# Slice the first 10 records off. 
sorted.each do |value|
  color = value[0].to_color(Magick::AllCompliance, false, Magick::QuantumDepth)
  percentage = (value[1].to_f / total_pixels.to_f) * 100.to_f
  color_map << {:count => value[1], :color_value => color, :percentage => percentage}
end

color_map.each do |color|
  puts color[:percentage].to_s + " - " + color[:count].to_s + " - " + color[:color_value]
end

puts "Total pixels is: #{total_pixels}"