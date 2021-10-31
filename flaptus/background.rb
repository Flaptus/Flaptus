class Background
	def initialize
		@image = Gosu::Image.new("#{ROOT_PATH}/assets/images/backgroundp.png")
		@x = 0
	end

	def move(speed)
		@x -= speed * 0.1
		if @x < WIDTH - @image.width
			@x = 0
		end
	end

	def draw
		@image.draw(@x, 0, ZOrder::BACKGROUND)
	end
end
