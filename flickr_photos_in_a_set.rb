#!/usr/bin/env ruby -wKU

# Download a set of photos from flickr. Will download 2000 images from a photo set.
# Make executeable and use like so:
# ./flickr_photos_in_a_set.rb SET_NUMBER /path/to/save/directory

require 'rubygems'
require 'flickraw'
require 'net/http'

class PhotosInASet

  attr_accessor :save_directory, :set_number
  
  def initialize(args = {})
    @save_directory = args[:save_directory]
    @set_number     = args[:set_number]
    config = File.open('config.yaml') { |yf| YAML::load( yf ) }
    FlickRaw.api_key        = config["flickr_api_key"]["value"]
    FlickRaw.shared_secret  = config["flickr_shared_secret"]["value"]
    FileUtils.mkdir(@save_directory) unless File.exist?(@save_directory)
  end
    
  def pull_photos
    photos = flickr.photosets.getPhotos(:photoset_id => self.set_number, :per_page => '2000', :page => '1')
    photos.photo.each do |photo|
      begin
        available_image_sizes = flickr.photos.getSizes(:photo_id => photo.id)
        original_image_url = available_image_sizes.find {|x| x.label == "Original"}.source.gsub("\\","").gsub(" ", "")
        unless File.exist?(File.join(self.save_directory,File.basename(original_image_url)))
          puts "Downloading: #{original_image_url}"
          url = URI.parse(original_image_url)
          req = Net::HTTP::Get.new(url.path)
          res = Net::HTTP.start(url.host, url.port) {|http|http.request(req)}
          File.open(File.join(self.save_directory,File.basename(original_image_url)), 'wb') do |file|
            file.write(res.body)
          end
        else
          puts "Skipping #{original_image_url}"
        end
        # Shouldn't have to do this shizzz... but it cuts memory useage in half! (on my box: MBP 2.667 2gb RAM)
        GC.start
      rescue NoMethodError => e
        # this will happen if 'source' isn't in the returned XML because the user decided to hide the original size
        puts "Photo unavailable - #{photo.id}"
        next
      end
    end
  end

end

set_number = ARGV[0]
save_dir = ARGV[1]

set = PhotosInASet.new(:set_number => set_number, :save_directory => save_dir)
set.pull_photos