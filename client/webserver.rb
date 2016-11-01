#!/usr/bin/ruby


# ssh pi@192.168.54.125

require 'webrick'

require_relative 'lib'

def update_sign(text)
  font = muni_sign_font(File.join(File.dirname(__FILE__), 'font'))

  # Only debugging: $stderr.puts arrival_times.inspect
  texts_for_sign = []
  texts_for_sign << font.render_multiline(text, 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH)

  if texts_for_sign && !texts_for_sign.empty?
    text_for_sign = texts_for_sign.map(&:zero_one).join("\n\n")
  else
    # Empty predictions array: this may be just nighttime.
    text_for_sign = font.render_multiline(["No routes", "until next morning."], 8, :ignore_shift_h => true, :distance => 0, :fixed_width => LED_Sign::SCREEN_WIDTH).zero_one
  end
  # LED_Sign.pic(text_for_sign)
  $stderr.puts text_for_sign
end


class MyServlet < WEBrick::HTTPServlet::AbstractServlet
    def do_GET (request, response)
        if request.query["line_1"] || request.query["line_2"]
            line_1 = request.query["line_1"]
            line_2 = request.query["line_2"]

            text = update_sign([line_1, line_2])

            response.status = 200
            response.content_type = "text/plain"
            result = text
            
            # case request.path
            #     when "/add"
            #         result = MyNormalClass.add(a, b)
            #     when "/subtract"
            #         result = MyNormalClass.subtract(a, b)
            #     else
            #         result = "No such method"
            # end
            
            response.body = result.to_s + "\n"
        else
            response.status = 200
            response.body = "<html>
                              <form accept-charset='UTF-8' action='/' class='new_user' id='new_user' method='get'>
                                <label for='line_1'>Line 1</label>
                                <input name='line_1' type='text' value=''>
                                <br>
                                <label for='line_2'>Line 2</label>
                                <input name='line_2' type='text' value=''>
                                <input class='button' data-disable-submit='submitting...' type='submit' value='Submit'>
                              </form>
                            </html>"
        end
    end
end

server = WEBrick::HTTPServer.new(:Port => 1234)
 
server.mount "/", MyServlet
 
trap("INT") {
    server.shutdown
}
 
server.start


