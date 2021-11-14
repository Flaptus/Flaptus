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
			Gosu::Image.new("#{ROOT_PATH}/assets/images/fullscreen.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/fullscreen_hover.png")
		]

		@fullscreen_images = [
			Gosu::Image.new("#{ROOT_PATH}/assets/images/unfullscreen.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/unfullscreen_hover.png")
		]

		super *@smallscreen_images

		@full = false
	end

	def click
		@full = !@full
		self.change_images(*(@full ? @fullscreen_images : @smallscreen_images))
	end
end



class MuteButton < Button
	def initialize
		@mute_images = [
			Gosu::Image.new("#{ROOT_PATH}/assets/images/mute.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/mute_hover.png")
		]

		@unmute_images = [
			Gosu::Image.new("#{ROOT_PATH}/assets/images/unmute.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/unmute_hover.png")
		]

		super *@mute_images

		@muted = false
	end

	def click
		@muted = !@muted
		self.change_images(*(@muted ? @unmute_images : @mute_images))
	end
end



class SfxButton < Button
	def initialize
		@mute_images = [
			Gosu::Image.new("#{ROOT_PATH}/assets/images/sfx.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/sfx_hover.png")
		]

		@unmute_images = [
			Gosu::Image.new("#{ROOT_PATH}/assets/images/unsfx.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/unsfx_hover.png")
		]

		super *@mute_images

		@muted = false
	end

	def click
		@muted = !@muted
		self.change_images(*(@muted ? @unmute_images : @mute_images))
	end
end



class LeaderboardButton < Button
	def initialize
		super(
			Gosu::Image.new("#{ROOT_PATH}/assets/images/trophy.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/trophy_hover.png")
		)
	end
end



class CloseButton < Button
	def initialize
		super(
			Gosu::Image.new("#{ROOT_PATH}/assets/images/close.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/close_hover.png")
		)
	end
end



class LeftArrowButton < Button
	def initialize
		super(
			Gosu::Image.new("#{ROOT_PATH}/assets/images/left_arrow.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/left_arrow_hover.png")
		)
	end
end



class RightArrowButton < Button
	def initialize
		super(
			Gosu::Image.new("#{ROOT_PATH}/assets/images/right_arrow.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/right_arrow_hover.png")
		)
	end
end



class SignupButton < Button
	def initialize
		super(
			Gosu::Image.new("#{ROOT_PATH}/assets/images/signup.png"),
			Gosu::Image.new("#{ROOT_PATH}/assets/images/signup_hover.png")
		)
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
