#!/usr/bin/env ruby

# Parses the itunes playlist xml file and sticks it in a mysql table.

# Gem requirements:
#   ActiveRecord
#   Hpricot

# Create a database called "itunes_library"
# Schema is as follows:
# CREATE TABLE `tracks` (
#   `id` int(11) NOT NULL auto_increment,
#   `name` varchar(255) NOT NULL,
#   `artist` varchar(255) NOT NULL,
#   `album` varchar(255) default NULL,
#   `genre` varchar(255) default NULL,
#   `size` int(11) default NULL,
#   `total_time` int(11) default NULL,
#   `track_number` int(11) default NULL,
#   `year` int(11) default NULL,
#   `date_modified` datetime default NULL,
#   `date_added` datetime default NULL,
#   `bit_rate` int(11) default NULL,
#   `sample_rate` int(11) default NULL,
#   `location` varchar(255) default NULL,
#   PRIMARY KEY  (`id`),
#   KEY `ARTIST` (`artist`),
#   KEY `NAME` (`name`),
#   KEY `ALBUM` (`album`)
# ) ENGINE=MyISAM AUTO_INCREMENT=23363 DEFAULT CHARSET=utf8;

require 'rubygems'
require 'active_record'
require 'hpricot'

puts "Starting..."

ActiveRecord::Base.establish_connection(  
  :adapter  => 'mysql',   
  :database => 'itunes_library',   
  :username => 'root',   
  :password => '',   
  :host     => 'localhost')
  
# A "Track" represents a song from the iTunes library.
class Track < ActiveRecord::Base
  
  # 'Cheap' validation. No point storing the same song twice upon multiple runs of this script.
  validates_uniqueness_of :location
  validates_presence_of :album
  
  # Pass in the date_modified string and use DateTime.parse to convert it into a date object.
  def date_modified=(date_modified)
    write_attribute(:date_modified, DateTime.parse(date_modified))
  end
  
  # Pass in the date_added string and use DateTime.parse to convert it into a date object.
  def date_added=(date_added)
    write_attribute(:date_added, DateTime.parse(date_added))
  end
    
end

status = []  # A lame progress bar
errors = []  # If any errors occur during this operation, store them in this array for print out after operation is complete.

puts "Opening itunes file..."

# Open the iTunes library xml file. You'll probably have to change this unless your username is 'dave'. Probably should be a script argument or constant. 
doc = Hpricot.XML(File.read("/Users/dave/Music/iTunes/iTunes Music Library.xml"))
(doc/'dict/dict')[1..-1].each do |element|
  args = {}
  (element/'key').each do |e|
    key   = e.inner_text.downcase.gsub(" ", "_").to_sym
    # Only care about the following track metadata
    if [:name, :artist, :album, :genre, :size, :total_time, :track_number, :year, :date_modified, :date_added, :bit_rate, :sample_rate, :location].include?(key)
      value = e.next.inner_text
      args.merge!({key => value})
    end
  end
  status << "."
  begin
    Track.create(args)
  rescue ActiveRecord::StatementInvalid => e
    errors << e
    next
  end
  puts status.to_s
end

puts "--------------------------"
puts "Saved #{Track.count(:all)} records"
puts "--------------------------"
puts "Did not save the following records:"

errors.each do |error|
  puts error
  puts "******"
end