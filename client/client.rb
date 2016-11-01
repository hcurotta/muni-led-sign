#!/usr/bin/ruby

require 'optparse'
require 'webrick'

require_relative 'lib'

font = muni_sign_font(File.join(File.dirname(__FILE__), 'font'))

options = {
  :update_interval => 30,
}

OptionParser.new do |opts|
  opts.banner = "Usage: client.rb --update-interval 60"

  opts.on('--update-interval SECONDS', Integer, "Update sign each number of seconds") {|v| options[:update_interval] = v}
end.parse!




def update_sign(font, options)
  # Only debugging: $stderr.puts arrival_times.inspect
  texts_for_sign = []
  texts_for_sign << font.render_multiline(["line 1", "line 2"], 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH)

  if texts_for_sign && !texts_for_sign.empty?
    text_for_sign = texts_for_sign.map(&:zero_one).join("\n\n")
  else
    # Empty predictions array: this may be just nighttime.
    text_for_sign = font.render_multiline(["No routes", "until next morning."], 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH).zero_one
  end
  # LED_Sign.pic(text_for_sign)
  $stderr.puts text_for_sign
end

while true
  begin
    update_sign(font, options)
  rescue => e
    $stderr.puts "Well, we continue despite this error: #{e}\n#{e.backtrace.join("\n")}"
  end
  sleep(options[:update_interval])
end

