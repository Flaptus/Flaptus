class Background
	IMAGE = Gosu::Image.new("#{ROOT_PATH}/assets/images/backgroundp.png")

	def initialize
		@image = Background::IMAGE
		@x = 0.0
	end

	def move(speed)
		@x -= speed * 0.1
		if @x < -@image.width
			@x = 0
		end
	end

	def draw
		@image.draw(@x, 0, ZOrder::BACKGROUND)
		@image.draw(@x + @image.width, 0, ZOrder::BACKGROUND)
	end
end
