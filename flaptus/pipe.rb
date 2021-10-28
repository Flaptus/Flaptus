class Pipe
	attr_reader :image, :x, :width
	attr_accessor :passed_player

	def initialize(direction)
		@image = Gosu::Image.new("#{ROOT_PATH}/assets/images/rock_#{direction}.png")
		@x = @y = 0.0
		@height = @image.height
		@width = @image.width
		@passed_player = false
	end

	def warp(x, y)
		@x, @y = x, y
	end

	def move(speed)
		@x -= 2 * speed
	end

	def within_x?(object)
		object_left = object.x
		object_right = object.x + object.width

		(object_left > @x && object_left < @x + @width) || (object_right > @x && object_right < @x + @width)
	end

	def within_gap_y?(object, gap_height)
		object_top = object.y
		object_bottom = object.y + object.height

		object_top > @y + @height && object_bottom < @y + @height + gap_height
	end

	def draw
		@image.draw(@x, @y, ZOrder::PIPES)
	end
end
