#!/usr/bin/env ruby -wKU

# == Pull a set of photos from flickr
# 
# Download a set of photos from flickr. Will download 2000 images from a photo set.
#
# == About
# Author:: Dave Hoefler
# License::   Distributes under the same terms as Ruby
#
# == Useage
# * Make executeable and use like so:
# * ./flickr_photos_in_a_set.rb SET_NUMBER /path/to/save/directory
#
# == Required gems
# * rubygems
# * flickraw - http://flickraw.rubyforge.org/0.4.5/

require 'rubygems'
require 'flickraw'
require 'net/http'

# This class will pull photos from flickr in a specified set. Must have a config.yaml in 
# the same directory as this class specifying your api key and shared secret key. See
# config.yaml.example included in this directory. 
class PhotosInASet
  
  attr_accessor :save_directory, :set_number
  
  # config.yaml should look like so:
  #
  # flickr_api_key:
  #   value: 1231jkj3k12j3k123jk12
  # flickr_shared_secret:
  #   value: j21l3j21l23
  CONFIG_PATH = File.join(File.dirname(__FILE__), 'config.yaml')
  
  # When creating a new PhotosInASet object, specify these arguments:
  # * {:save_directory => '/Users/dave/Desktop/flickr_photos', :set_number => 1111111}
  def initialize(args = {})
    @save_directory = args[:save_directory]
    @set_number     = args[:set_number]
    
    # Open the config.yaml 
    config                  = File.open(CONFIG_PATH) { |yf| YAML::load( yf ) }
    FlickRaw.api_key        = config["flickr_api_key"]["value"]
    FlickRaw.shared_secret  = config["flickr_shared_secret"]["value"]
    
    # Create the save directory if it doesn't exist
    FileUtils.mkdir(@save_directory) unless File.exist?(@save_directory)
  end
  
  # Download the images from flickr based on the set number and store them in the specified save_directory.
  #
  # * Uses flickraw to get all the IDS of the images in a set
  # * Iterates through each photo and uses flickraw to download the 'Original' size
  # * Downloads the 'Original' image if it exists
  # * Saves the 'Original' image in the specified save_directory
  def pull_photos
    # Grab the photo set from flickr
    photos = flickr.photosets.getPhotos(:photoset_id => self.set_number, :per_page => '2000', :page => '1')
    
    # Iterate through each photo checking to see if the "Original" size exists in the returned XML
    photos.photo.each do |photo|
      begin
        available_image_sizes = flickr.photos.getSizes(:photo_id => photo.id)
        original_image_url = available_image_sizes.find {|x| x.label == "Original"}.source.gsub("\\","").gsub(" ", "")
        
        # Only save the image if it doesn't exist in the save directory
        unless File.exist?(File.join(self.save_directory,File.basename(original_image_url)))
          puts "Downloading: #{original_image_url}"
          url = URI.parse(original_image_url)
          req = Net::HTTP::Get.new(url.path)
          res = Net::HTTP.start(url.host, url.port) {|http|http.request(req)}
          File.open(File.join(self.save_directory,File.basename(original_image_url)), 'wb') do |file|
            file.write(res.body) # write the image file
          end
        else
          # If the image already exists, we'll skip the download of the image.
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

set_number = ARGV[0]  # The set number to pull
save_dir = ARGV[1]    # The path to where the photos will be saved

# Make sure both arguments exist. Should probably use optparse to do this. It would be cleaner.
if set_number && save_dir
  # Create a new PhotosInASet object and pull the photos
  set = PhotosInASet.new(:set_number => set_number, :save_directory => save_dir)
  set.pull_photos
else
  puts "-----------------------------------------------------"
  puts "Usage: ./flickr_photos_in_a_set.rb SET_NUMBER SAVE_DIR"
  puts "-----------------------------------------------------"
end