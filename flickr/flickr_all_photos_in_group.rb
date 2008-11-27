#!/usr/bin/env ruby

# Pull all the photos with an original size from a specified group.
# TODO: Document this script.

require 'rubygems'
begin
  require 'flickraw'
rescue Exception => e
  puts "flickr error: #{e}"
  sleep(10)
  retry
end
require 'net/http'
require 'hpricot'
require 'open-uri'


class GroupPhotos
  
  attr_accessor :save_directory, :group_id
  
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
    @group_id       = args[:group_id]
    
    # Open the config.yaml 
    config                  = File.open(CONFIG_PATH) { |yf| YAML::load( yf ) }
    begin
      FlickRaw.api_key        = config["flickr_api_key"]["value"]
      FlickRaw.shared_secret  = config["flickr_shared_secret"]["value"]
    rescue Exception => e
      puts e
      sleep(10)
      retry
    end
    
    # Create the save directory if it doesn't exist
    FileUtils.mkdir(@save_directory) unless File.exist?(@save_directory)
  end
  
  #TODO CLEAN THIS CRAP UP!
  def pull_photos    
    begin
      doc = Hpricot(open("http://www.flickr.com/groups/#{self.group_id}/pool/"))
    rescue Exception
      puts "Error when trying to open the flickr pool URL to get total number of images in this pool. Will retry..."
      sleep(10)
      retry
    end

    total_number_of_photos = doc.search("//div[@class='Results']").inner_html.gsub(/[a-zA-Z,\(\)]/,"").to_f
    per_page = 500  
    flickr_request_looper = (total_number_of_photos.to_f / 500.0).ceil
    times_to_loop = 1
    page = 1
    
    while times_to_loop <= flickr_request_looper
      begin
        group_photos = flickr.groups.pools.getPhotos(:group_id  => self.group_id, 
                                                     :per_page  => per_page,
                                                     :page      => page)
      rescue Exception
        puts "Connection error when trying 'flickr.groups.pools.getPhoto()'. Will retry in 10 seconds..."
        sleep(10)
        retry
      end
      
      group_photos.each do |photo|
        begin
          
          # TODO make this its own method with proper error handeling 
          begin
            available_image_sizes = flickr.photos.getSizes(:photo_id => photo.id)
          rescue Exception
            puts "Connection error when trying 'flickr.photos.getSizes'. Will retry..."
            sleep(10)
            retry
          end
          
          original_image_url = available_image_sizes.find {|x| x.label == "Original"}.source.gsub("\\","").gsub(" ", "")
          
          unless File.exist?(File.join(self.save_directory,File.basename(original_image_url)))
            puts "Downloading: #{original_image_url}"

            # TODO make this its own method with proper error handeling 
            begin
              url = URI.parse(original_image_url)
              req = Net::HTTP::Get.new(url.path)
              res = Net::HTTP.start(url.host, url.port) {|http|http.request(req)}
            rescue Exception
              puts "Connection error when trying to download the image. Will retry..."
              sleep(10)
              retry
            end
            
            # TODO make this its own method with proper error handeling 
            File.open(File.join(self.save_directory,File.basename(original_image_url)), 'wb') do |file|
              file.write(res.body) # write the image file
            end
          else
            # If the image already exists, we'll skip the download of the image.
            puts "Skipping #{original_image_url}"
          end
        rescue NoMethodError => e
          puts "----------------------- MAJOR ERROR -------------------"
          puts e
          puts "...will retry..."
          puts "--------------------- END MAJOR ERROR -----------------"
          sleep(10)
          retry
        end
      end
      page += 1
      times_to_loop +=1
    end
    
  end

end

group_id  = ARGV[0]    
save_dir  = ARGV[1]    # The path to where the photos will be saved

# Make sure both arguments exist. Should probably use optparse to do this. It would be cleaner.
if group_id && save_dir
  # Create a new UserPhotos object and pull the photos
  group = GroupPhotos.new(:group_id => group_id, :save_directory => save_dir)
  group.pull_photos
else
  puts "-----------------------------------------------------"
  puts "Usage: ./flickr_all_photos_in_group.rb GROUP_ID SAVE_DIR"
  puts "-----------------------------------------------------"
end
