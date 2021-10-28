class Button
	attr_reader :width, :height

	def initialize(base_image, hover_image=base_image)
		@base_image, @hover_image = base_image, hover_image

		@x = @y = 0.0

		@hover = false
		@width = @base_image.width
		@height = @base_image.height
	end

	def warp(x, y)
		@x, @y = x, y
	end

	def check_hover(mouse_x, mouse_y)
		@hover = @y < mouse_y && @y + @height > mouse_y && @x < mouse_x && @x + @width > mouse_x
		@hover
	end

	def hover? = @hover

	def click; end

	def draw
		(@hover ? @hover_image : @base_image).draw(@x, @y, ZOrder::UI)
	end

	private

	def change_images(base_image, hover_image)
		@base_image, @hover_image = base_image, hover_image
	end
end



class FullScreenButton < Button
	def initialize
		@smallscreen_images = [
			Gosu::Image.new("#{ROOT_PATH}/assets/images/fullscreen_button_smallscreen.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/fullscreen_button_smallscreen_hover.png")
		]

		@fullscreen_images = [
			Gosu::Image.new("#{ROOT_PATH}/assets/images/fullscreen_button_fullscreen.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/fullscreen_button_fullscreen_hover.png")
		]

		super *@smallscreen_images

		@full = false
	end

	def click
		@full = !@full
		self.change_images(*(@full ? @fullscreen_images : @smallscreen_images))
	end
end



class YesButton < Button
	def initialize
		super(
			Gosu::Image.new("#{ROOT_PATH}/assets/images/yes_button.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/yes_button_hover.png")
		)
	end
end

class NoButton < Button
	def initialize
		super(
			Gosu::Image.new("#{ROOT_PATH}/assets/images/no_button.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/no_button_hover.png")
		)
	end
end
