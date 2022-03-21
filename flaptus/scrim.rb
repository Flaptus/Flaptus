SCRIM_COLOUR = 0x77_444444

class Scrim
	def initialize
		@width = WIDTH
		@height = HEIGHT
	end

	def draw
		Gosu::draw_rect(
			0, 0,
			@width, @height,
			Gosu::Color.argb(SCRIM_COLOUR),
			ZOrder::UI
		)
	end
end
