#!/usr/bin/env ruby

# == Description
# 
# Download all of a user's photos from flickr.
#
# == About
# Author:: Dave Hoefler
# License::   Distributes under the same terms as Ruby
#
# == Useage
# * Make executeable and use like so:
# * ./flickr_all_users_photos.rb USER_NAME /path/to/save/directory
#
# == Required gems
# * rubygems
# * flickraw - http://flickraw.rubyforge.org/0.4.5/

require 'rubygems'
require 'flickraw'
require 'net/http'

# This class will pull all of a user's original sized images from flickr. Must have a config.yaml in 
# the same directory as this class specifying your api key and shared secret key. See
# config.yaml.example included in this directory. 
class PhotosInASet
  
  attr_accessor :save_directory, :user_name
  
  # config.yaml should look like so:
  #
  # flickr_api_key:
  #   value: 1231jkj3k12j3k123jk12
  # flickr_shared_secret:
  #   value: j21l3j21l23
  CONFIG_PATH = File.join(File.dirname(__FILE__), 'config.yaml')
  
  # Pass in the following args in the hash:
  # * :save_directory => save_directory
  # * :user_name      => username
  def initialize(args = {})
    @save_directory = args[:save_directory]
    @user_name     = args[:user_name]
    
    # Open the config.yaml 
    config                  = File.open(CONFIG_PATH) { |yf| YAML::load( yf ) }
    FlickRaw.api_key        = config["flickr_api_key"]["value"]
    FlickRaw.shared_secret  = config["flickr_shared_secret"]["value"]
    
    # Create the save directory if it doesn't exist
    FileUtils.mkdir(@save_directory) unless File.exist?(@save_directory)
  end
  
  def pull_photos
    username_info = flickr.people.findByUsername(:username => self.user_name)
    user_info = flickr.people.getInfo(:user_id => username_info.nsid)
    
    # We can only get 500 photos at a time using flickraw, so see how many images there are and divide by 500.
    # This will dictate how many times we have to call flickr.people.getPublicPhotos(:per_page)
    flickr_request_looper = (user_info.photos.count.to_f / 500.0).ceil
    times_to_loop = 1
    
    # Let's get the max results allowed in '1' request to flickr
    per_page = 500
    
    # Set up which page to get initially. Incremented in the loop below.
    page = 1
    
    # Set the loop up so the times to loop is less than or equal to the calculation that returns 'flickr_request_looper'
    while times_to_loop <= flickr_request_looper
      photos = flickr.people.getPublicPhotos(:user_id     => user_info.nsid, 
                                             :safe_search => 'safe_search',
                                             :extras      => 'extras',
                                             :per_page    => per_page,
                                             :page        => page)
      photos.each do |photo|
        begin
          available_image_sizes = flickr.photos.getSizes(:photo_id => photo.id)
          original_image_url = available_image_sizes.find {|x| x.label == "Original"}.source.gsub("\\","").gsub(" ", "")
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
        rescue NoMethodError => e
          # this will happen if 'source' isn't in the returned XML because the user decided to hide the original size
          puts "Photo unavailable - #{photo.id}"
          next
        end
      end
      page += 1 # Increase the page number to get
      times_to_loop += 1 
    end
  end

end

user_name = ARGV[0]    # The flickr username 
save_dir  = ARGV[1]    # The path to where the photos will be saved

# Make sure both arguments exist. Should probably use optparse to do this. It would be cleaner.
if user_name && save_dir
  # Create a new PhotosInASet object and pull the photos
  set = PhotosInASet.new(:user_name => user_name, :save_directory => save_dir)
  set.pull_photos
else
  puts "-----------------------------------------------------"
  puts "Usage: ./flickr_photos_in_a_set.rb USER_NAME SAVE_DIR"
  puts "-----------------------------------------------------"
end