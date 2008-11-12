require 'rubygems'
require 'id3lib'
include ID3Lib

# Extract the album artwork for 99% of the tracks in your itunes library.
# Change ITUNES_DIR to point to your 'iTunes Music' root
# Change ALBUM_ART_SAVE_DIR to point to a folder where you want to save the cover art
# Make executeable and run!

VALID_MEDIA_TYPES = %w{mp3 wav aiff aac}.collect {|x| [x, x.upcase]}.flatten.join(",")
ITUNES_DIR = "/Users/dave/Music/iTunes/iTunes Music"
ALBUM_ART_SAVE_DIR = '/Users/dave/Desktop/album_art'

$KCODE = 'u'

def content_type(track)
  track.frame(:APIC)[:mimetype] =~ /\/(.*)$/
  $1.nil? ? 'png' : $1
end

Dir[File.expand_path(File.join(ITUNES_DIR,"**","*{#{VALID_MEDIA_TYPES}}"))].each do |file|
  begin
    track = Tag.new(file)
    unless track.frame(:APIC).nil?
      unless File.exist?(File.join(ALBUM_ART_SAVE_DIR, "#{track.artist} - #{track.album}.#{content_type(track)}"))
        File.open(File.join(ALBUM_ART_SAVE_DIR, "#{track.artist} - #{track.album}.#{content_type(track)}"), 'wb') do |song_file|
          song_file.write track.frame(:APIC)[:data]
          puts "Saved album art for: #{file} - #{track.album}.#{content_type(track)}"
        end
      end
    end
  rescue Errno::ENOENT
    p "Errno:ENOENT: Error saving artwork for: #{File.basename(file)}"
    next
  rescue ArgumentError
    p "ArgumentError: Error saving artwork for: #{File.basename(file)}"
  end
end
