#!/usr/bin/env ruby -wKU

# Take time intervaled pictures using your isight. Make the process a daemon and run it in the background.

# VERY IMPORTANT: Must install 'isightcapture' and add it to your path:
# =>  http://www.macupdate.com/info.php/id/18598

require 'rubygems'
require 'daemons'

options = {
    :app_name   => "image_capture",
    :ARGV       => ['start'],
    :dir_mode   => :script,
    :dir        => 'pids',
    :multiple   => false,
    :ontop      => false,
    :monitor    => true,
    :log_output => true
  }

Daemons.run(File.join(File.dirname(__FILE__), 'image_capture.rb'))


# To make a movie from all the captured images, just run these two commands:
# convert -delay 10 *.png m2v:time_lapse.m2v
# ffmpeg -i time_lapse.m2v -vcodec mjpeg -qscale 1 -an time_lapse_final.avi


# This is a one liner that'll work too:
# convert -delay 1 *.png mpeg:time_lapse.mpeg