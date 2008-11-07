#!/usr/bin/env ruby -wKU

# Change the path below to point to a directory where you want to save the images.

loop do
  system("isightcapture /Users/dave/Pictures/motion_capture/#{Time.now.to_i}.png")
  sleep 30  # == 30 seconds. Change if desired.
end