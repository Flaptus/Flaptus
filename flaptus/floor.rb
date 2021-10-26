class Floor
	attr_reader :y, :image

	def initialize
		@image = Gosu::Image.new("#{ROOT_PATH}/assets/images/floor.png")
		@x = @y = 0.0
	end

	def warp(x, y)
		@x, @y = x, y
	end

	def move(speed)
		@x -= 2 * speed
		@x = 0 if @x + @image.width / 2 <= 0
	end

	def draw
		@image.draw(@x, @y, ZOrder::FLOOR)
	end
end
