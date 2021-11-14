class TextBox < Gosu::TextInput
	WIDTH                = 240
	PADDING              = 5
	CARET_COLOUR         = 0xffffffff
	ACTIVE_COLOUR        = 0xff33ff33
	INACTIVE_COLOUR      = 0xcc666666
	SELECTION_COLOUR     = 0xcc0000ff
	ACTIVE_TEXT_COLOUR   = 0xffffffff
	INACTIVE_TEXT_COLOUR = 0xffcccccc

	attr_reader :x, :y

	def initialize(window, placeholder: nil)
		super()

		@x = @y = 0.0
		@window, @placeholder = window, placeholder

		@font = Gosu::Font.new(35, name: Gosu::default_font_name)

	end

	def warp(x, y)
		@x, @y = x, y
	end

	def filter(txt)
		txt if self.text.length + txt.length <= 12
	end

	def draw
		background_colour = @window.text_input == self ? ACTIVE_COLOUR : INACTIVE_COLOUR
		font_colour = @window.text_input == self ? ACTIVE_TEXT_COLOUR : INACTIVE_TEXT_COLOUR

		Gosu.draw_quad(
			x - PADDING,         y - PADDING,          background_colour,
			x + width + PADDING, y - PADDING,          background_colour,
			x - PADDING,         y + height + PADDING, background_colour,
			x + width + PADDING, y + height + PADDING, background_colour, ZOrder::UI
		)

		pos_x = x + @font.text_width(self.text[0...self.caret_pos])
		sel_x = x + @font.text_width(self.text[0...self.selection_start])

		Gosu.draw_quad(
			sel_x, y,          SELECTION_COLOUR,
			pos_x, y,          SELECTION_COLOUR,
			sel_x, y + height, SELECTION_COLOUR,
			pos_x, y + height, SELECTION_COLOUR, ZOrder::UI
		)

		if @window.text_input == self
			Gosu.draw_line(
				pos_x, y,          CARET_COLOUR,
				pos_x, y + height, CARET_COLOUR, ZOrder::UI
			)
		end

		txt = (@window.text_input == self && self.text != "") || self.text != "" ? self.text : @placeholder
		@font.draw_text(txt, x, y, ZOrder::UI, 1.0, 1.0, font_colour)
	end

	def height = @font.height
	def width  = WIDTH > @font.text_width(self.text) ? WIDTH : @font.text_width(self.text)

	def hover?(mouse_x, mouse_y)
		mouse_x > x - PADDING && mouse_x < x + width + PADDING && mouse_y > y - PADDING && mouse_y < y + height + PADDING
	end

	def move_caret(mouse_x)
		1.upto(self.text.length) do |i|
			if mouse_x < x + @font.text_width(self.text[0...i])
				self.caret_pos = self.selection_start = i - 1
				return
			end
		end
	end
end
