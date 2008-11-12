#!/usr/bin/env ruby -wKU

require 'rubygems'
require 'flickraw'
require 'net/http'

class PhotosFromTag
  
  attr_accessor :save_directory, :tag
  
  CONFIG_PATH = File.join(File.dirname(__FILE__), 'config.yaml')

  def initialize(args = {})
    @save_directory = args[:save_directory]
    @tag            = args[:tag]
    @username       = args[:username]
        
    # Open the config.yaml 
    config                  = File.open(CONFIG_PATH) { |yf| YAML::load( yf ) }
    FlickRaw.api_key        = config["flickr_api_key"]["value"]
    FlickRaw.shared_secret  = config["flickr_shared_secret"]["value"]
    
    # Create the save directory if it doesn't exist
    FileUtils.mkdir(@save_directory) unless File.exist?(@save_directory)
  end
  
  def pull_photos
    username_info = flickr.people.findByUsername(:username => @username)
    # user_info = flickr.people.getInfo(:user_id => username_info.nsid)
    photos = flickr.photos.search(:user_id => username_info.nsid, :tags => self.tag, :per_page => 500)
    
    # Iterate through each photo checking to see if the "Original" size exists in the returned XML
    photos.photo.each do |photo|
      begin
        available_image_sizes = flickr.photos.getSizes(:photo_id => photo["id"])
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

username  = ARGV[0]
tag       = ARGV[1]  
save_dir  = ARGV[2]    # The path to where the photos will be saved

# Make sure both arguments exist. Should probably use optparse to do this. It would be cleaner.
if tag && save_dir && username
  tag = PhotosFromTag.new({:tag => tag, :save_directory => save_dir, :username => username})
  tag.pull_photos
else
  puts "-----------------------------------------------------"
  puts "Usage: ./flickr_photos_in_a_set.rb tag SAVE_DIR"
  puts "-----------------------------------------------------"
end