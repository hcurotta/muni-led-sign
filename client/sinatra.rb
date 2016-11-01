#!/usr/bin/ruby


# ssh pi@192.168.54.125

require 'sinatra'

require_relative 'lib'

get '/sales/premium' do
  process_message("Premium Sign-up!", params[:amount])
end

get '/sales/images' do 
  process_message("Image Sale!", params[:amount])
end

get '/collection/published' do
  total_count = params[:count]
  name = params[:name]n
  play_yeehaa
  update_sign(["Way to go #{name}", "#{total_count} published!"])
end


def process_message(sale_type, amount)
  amount = (amount.to_f / 100)

  pretty_print_amount = sprintf('$%0.2f', amount).gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  update_sign(["Image Sale!", pretty_print_amount])
  
  num_dongs = (amount / 1000).to_i
  
  if sale_type == "Image Sale!"
    play_dong(num_dongs)
  else
    play_dong(1)
  end
end

def update_sign(text)
  font = muni_sign_font(File.join(File.dirname(__FILE__), 'font'))

  # Only debugging: $stderr.puts arrival_times.inspect
  texts_for_sign = []
  texts_for_sign << font.render_multiline(text, 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH)

  if texts_for_sign && !texts_for_sign.empty?
    text_for_sign = texts_for_sign.map(&:zero_one).join("\n\n")
  else
    text_for_sign = font.render_multiline(["no", "message"], 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH).zero_one
  end
  
  LED_Sign.pic(text_for_sign)
  $stderr.puts text_for_sign
end

def play_dong(num_dongs)
  play_sound(num_dongs, "~/dong-2.wav")
end

def play_yeehaa
  play_sound(1, "~/yeehaw.wav")
end


def play_sound(repeat_count, sound_file)
  command = ""

  repeat_count.times do |t|
    command = command + "omxplayer #{sound_file} --vol -1000;"
  end

  pid = Process.spawn("(#{command}) &")
  Process.detach(pid)
end