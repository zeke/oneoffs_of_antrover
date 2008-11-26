#!/usr/bin/env ruby

# Pull all the photos with an original size from a specified group.
# TODO: Document this script.

require 'rubygems'
require 'flickraw'
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
    FlickRaw.api_key        = config["flickr_api_key"]["value"]
    FlickRaw.shared_secret  = config["flickr_shared_secret"]["value"]
    
    # Create the save directory if it doesn't exist
    FileUtils.mkdir(@save_directory) unless File.exist?(@save_directory)
  end
  
  def pull_photos    
    doc = Hpricot(open("http://www.flickr.com/groups/#{self.group_id}/pool/"))

    total_number_of_photos = doc.search("//div[@class='Results']").inner_html.gsub(/[a-zA-Z,\(\)]/,"").to_f
    per_page = 500  
    flickr_request_looper = (total_number_of_photos.to_f / 500.0).ceil
    times_to_loop = 1
    page = 1
    
    while times_to_loop <= flickr_request_looper
      group_photos = flickr.groups.pools.getPhotos(:group_id  => self.group_id, 
                                                   :per_page  => per_page,
                                                   :page      => page)
      group_photos.each do |photo|
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
          puts e
        end
      end
      page += 1
      times_to_loop +=1
    end
    
    
  #   # We can only get 500 photos at a time using flickraw, so see how many images there are and divide by 500.
  #   # This will dictate how many times we have to call flickr.people.getPublicPhotos(:per_page)


  #   # Set the loop up so the times to loop is less than or equal to the calculation that returns 'flickr_request_looper'
  #   while times_to_loop <= flickr_request_looper
  #     photos = flickr.people.getPublicPhotos(:user_id     => user_info.nsid, 
  #                                            :safe_search => 'safe_search',
  #                                            :extras      => 'extras',
  #                                            :per_page    => per_page,
  #                                            :page        => page)
  #     photos.each do |photo|
  #       begin
  #         available_image_sizes = flickr.photos.getSizes(:photo_id => photo.id)
  #         original_image_url = available_image_sizes.find {|x| x.label == "Original"}.source.gsub("\\","").gsub(" ", "")
  #         unless File.exist?(File.join(self.save_directory,File.basename(original_image_url)))
  #           puts "Downloading: #{original_image_url}"
  #           url = URI.parse(original_image_url)
  #           req = Net::HTTP::Get.new(url.path)
  #           res = Net::HTTP.start(url.host, url.port) {|http|http.request(req)}
  #           File.open(File.join(self.save_directory,File.basename(original_image_url)), 'wb') do |file|
  #             file.write(res.body) # write the image file
  #           end
  #         else
  #           # If the image already exists, we'll skip the download of the image.
  #           puts "Skipping #{original_image_url}"
  #         end
  #       rescue NoMethodError => e
  #         # this will happen if 'source' isn't in the returned XML because the user decided to hide the original size
  #         puts "Photo unavailable - #{photo.id}"
  #         next
  #       end
  #     end
  #     page += 1 # Increase the page number to get
  #     times_to_loop += 1 
  #   end
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
