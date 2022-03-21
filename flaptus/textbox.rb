class TextBox < Gosu::TextInput
	WIDTH                = 240
	PADDING              = 4
	CARET_COLOUR         = 0xffffffff
	ACTIVE_COLOUR        = 0xff_2d832d
	INACTIVE_COLOUR      = 0x22_2d832d
	SELECTION_COLOUR     = 0xcc_0022dd
	ACTIVE_TEXT_COLOUR   = 0xff_eeffee
	INACTIVE_TEXT_COLOUR = 0xff_2d832d

	attr_reader :x, :y

	def initialize(window, placeholder: nil)
		super()

		@x = @y = 0.0
		@window, @placeholder = window, placeholder

		@font = Gosu::Font.new(30, name: "#{ROOT_PATH}/assets/fonts/Dosis.ttf")

	end

	def warp(x, y)
		@x, @y = x, y
	end

	def filter(txt)
		txt if self.text.length + txt.length <= 12
	end

	def draw
		ex = @x + PADDING
		ey = @y + PADDING

		ewidth  = width - PADDING
		eheight = height - PADDING * 2

		if @window.text_input != self
			bwidth = width + PADDING
			
			Gosu::draw_line(
				@x,          @y, Gosu::Color.argb(ACTIVE_COLOUR),
				@x + bwidth, @y, Gosu::Color.argb(ACTIVE_COLOUR),
				ZOrder::UI
			)

			Gosu::draw_line(
				@x + bwidth, @y,          Gosu::Color.argb(ACTIVE_COLOUR),
				@x + bwidth, @y + height, Gosu::Color.argb(ACTIVE_COLOUR),
				ZOrder::UI
			)

			Gosu::draw_line(
				@x + bwidth, @y + height, Gosu::Color.argb(ACTIVE_COLOUR),
				@x,          @y + height, Gosu::Color.argb(ACTIVE_COLOUR),
				ZOrder::UI
			)

			Gosu::draw_line(
				@x, @y + height, Gosu::Color.argb(ACTIVE_COLOUR),
				@x, @y,          Gosu::Color.argb(ACTIVE_COLOUR),
				ZOrder::UI
			)
		end

		background_colour = @window.text_input == self ? ACTIVE_COLOUR : INACTIVE_COLOUR
		font_colour = @window.text_input == self ? ACTIVE_TEXT_COLOUR : INACTIVE_TEXT_COLOUR

		Gosu.draw_quad(
			ex - PADDING,          ey - PADDING,           background_colour,
			ex + ewidth + PADDING, ey - PADDING,           background_colour,
			ex - PADDING,          ey + eheight + PADDING, background_colour,
			ex + ewidth + PADDING, ey + eheight + PADDING, background_colour, ZOrder::UI
		)

		pos_x = ex + @font.text_width(self.text[0...self.caret_pos])
		sel_x = ex + @font.text_width(self.text[0...self.selection_start])

		Gosu.draw_quad(
			sel_x, ey,           SELECTION_COLOUR,
			pos_x, ey,           SELECTION_COLOUR,
			sel_x, ey + eheight, SELECTION_COLOUR,
			pos_x, ey + eheight, SELECTION_COLOUR, ZOrder::UI
		)

		if @window.text_input == self
			Gosu.draw_line(
				pos_x, ey,           CARET_COLOUR,
				pos_x, ey + eheight, CARET_COLOUR, ZOrder::UI
			)
		end

		txt = (@window.text_input == self && self.text != "") || self.text != "" ? self.text : @placeholder
		@font.draw_text(txt, ex, ey, ZOrder::UI, 1.0, 1.0, font_colour)
	end

	def height = @font.height + 8
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
