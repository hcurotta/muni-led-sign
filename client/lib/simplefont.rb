# Library to work with simple fonts for rendering.
# It seemed easier to write a small font renderer than to tame fontconfig.

# Reads simple font files generated by scripts/genfont.pl, and renders text.
class SimpleFont
  def initialize(data)
    @glyphs = {}
    load_glyphs(data)
  end

  # Load more glyphs from data (as if generated by scripts/genfont.pl).
  # Supersedes previous glyphs on clash.
  def load_glyphs(data)
    lines = data.split("\n")
    # Whether we're anticipating a glyph header or a next line of the glyph.
    mode = :need_header
    # pointer to the record we currently read
    write_to = nil
    lines.each do |line|
      line.chomp!
      if (mode == :need_header) and (m = /(\d+) (\d+) (\d+)/.match(line))
        write_to = {:shift_h => m[2].to_i, :shift_v => m[3].to_i}
        @glyphs[m[1].to_i] = write_to
        mode = :need_line
      elsif mode == :need_line
        if line.empty?
          mode = :need_header
        else
          # This will write into @glyphs array as write_to references one of its
          # elements.
          write_to[:bitmap] ||= []
          write_to[:bitmap] << line.split('')
        end
      end
    end
  end

  # Render string given the max height above the baseline.  Returns rectangular
  # array, starting from top-left corner.
  # Opts: ignore_shift_h - whether to ignore shift_h read from the font.
  def render(string, height, opts = {})
    # We'll store, temporarily, bits in buf hash, where hash[[i,j]] is a bit i
    # points up, and j points right from the start of the baseline. 
    buf = {}
    width = 0
    # Technically, it should be String#split, but we don't support chars >127
    # anyway.
    string.each_byte do |c_code|
      glyph = @glyphs[c_code]
      add_shift_h = opts[:ignore_shift_h] ? 0 : glyph[:shift_h]
      glyph[:bitmap].each_with_index do |row, i|
        row.each_with_index do |bit, j|
          bit_row = (glyph[:shift_v] - 1) - i
          bit_col = width + j + add_shift_h
          buf[[bit_row, bit_col]] = bit
          #height = bit_row if height < bit_row
          raise "negative value for letter #{c_code}" if bit_row < 0
        end
        # Compute the new width.
      end
      width += (glyph[:bitmap][0] || []).length
      # Insert interval between letters.
      width += 1 + add_shift_h
    end
    # now render the final array
    result = []
    buf.each do |xy, bit|
      row = (height - 1) - xy[0]
      col = xy[1]
      result[row] ||= []
      result[row][col] = bit
    end
    # Fill nil-s with zeroes.
    result.map! do |row|
      expanded_row = row || []
      # Expand row up to width.
      if expanded_row.size < width
        expanded_row[width] = nil
        expanded_row.pop
      end
      # Replace nil-s in this row with zeroes.
      expanded_row.map{|bit| bit || 0}
    end
    return result
  end

  # Same as render, but renders several lines (it is an array), and places them
  # below each other.  Accepts the same options as "render," and also these:
  #   distance: distance between lines in pixels.
  def render_multiline(lines, line_height, opts = {})
    line_pics = lines.map {|line| render(line, line_height, opts)}
    line_pics.each {|lp| $stderr.puts lp.zero_one}
    # Compose text out of lines.  Center the lines.
    # Determine the width of the overall canvas.
    width = line_pics.map {|img| (img.first || []).length}.max
    # Create wide enough empty canvas.
    line_shift = line_height + (opts[:distance] || 1)
    canvas = (1..line_shift*lines.length).map do |_|
      (1..width).map{|_| 0}
    end
    # Put each line onto the canvas.
    line_pics.each_with_index do |line_pic, line_i|
      line_pic.each_with_index do |row, i|
        h_shift = (width - row.length) / 2
        row.each_with_index do |bit, j|
          canvas[line_i*line_shift + i][h_shift + j] = bit
        end
      end
    end
    canvas
  end
end

# Returns the default, most useful instance of the font used in signs.
def muni_sign_font(font_path)
  # Load generated font.
  sf = SimpleFont.new(IO.read(File.join(font_path, '7x7.simpleglyphs')))
  # Load amendments to the letters I don't like.
  sf.load_glyphs(IO.read(File.join(font_path, 'amends.simpleglyphs')))
  # Load local, application-specific glyphs.
  sf.load_glyphs(IO.read(File.join(font_path, 'specific.simpleglyphs')))

  return sf
end


