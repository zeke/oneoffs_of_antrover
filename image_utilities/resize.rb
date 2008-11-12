#!/usr/bin/env ruby
require 'rubygems'
require 'RMagick'
include ObjectSpace

# ./dhresize.rb "/Users/dave/Desktop/Vacation Pics/" 40
# ./dhresize.rb #{path to directory filled with images} #{percent to scale images}

PATH = ARGV[0]
SCALE = ARGV[1].to_f

RESIZED_IMAGES = File.join(PATH, "resized")
THUMBS = File.join(PATH, "resized", "thumbs")

Dir.mkdir(RESIZED_IMAGES) unless File.exists?(RESIZED_IMAGES)
Dir.mkdir(THUMBS) unless File.exists?(THUMBS)

def scale_image(image)
  resized_image = image.scale(SCALE * 0.01)
  resized_image.write(File.join(RESIZED_IMAGES, File.basename(image.filename)))
  puts "Saved scaled image for #{File.basename(image.filename)}"
end
def create_thumb(image)
  thumb = image.crop_resized(240, 180, Magick::NorthGravity)
  thumb.write(File.join(THUMBS, "thumb_" + File.basename(image.filename)))  
  puts "Saved thumb for #{File.basename(image.filename)}"
end

Dir.entries(PATH).each do |file|
  begin
    image = Magick::Image::read(File.join(PATH, file)).first
    scale_image(image)
    create_thumb(image)
  rescue Magick::ImageMagickError
  rescue NoMethodError
  end
  ObjectSpace.garbage_collect
end