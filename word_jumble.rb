#!/usr/bin/env ruby -wKU

# Word jumble script.

# Takes a string as input and scrambles it. 
# Think I stole this script from someone, but I don't remember. If it's yours, let me know and you'll get credit!

class String
  def scramble
    s = self.split(//).sort_by { rand }.join('')
    (s =~ /[A-Z]/ && s =~ /[a-z]/) ? s.capitalize : s
  end

  def scramble_words
    ret = []
    self.split(/\s+/).each { |nws|
      nws.scan(/^(\W*)(\w*)(\W*)$/) { |pre, word, post|
        ret << pre + word.scramble + post
      }
    }
    ret.join " "
  end
end

loop do
  print "Enter something: "
  str = gets.chomp
  exit if str.empty?
  puts str.scramble_words
end