BUTTON_TEXT_COLOUR = 0xff_eeffee
BUTTON_LIFT_COLOUR = 0xff_2d832d
BUTTON_SCIM_COLOUR = 0x22_2d832d

class Button
	attr_reader :width, :height
	#attr_writer :width, :height

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

	def resize(w, h)
		@width, @height = w, h
	end

	def check_hover(mouse_x, mouse_y)
		@hover = @y < mouse_y && @y + @height > mouse_y && @x < mouse_x && @x + @width > mouse_x
		@hover
	end

	def hover? = @hover

	def click; end

	def draw
		image = @hover ? @hover_image : @base_image

		image.draw_as_quad(
			@x,          @y,           Gosu::Color.argb(0xffffffff),
			@x + @width, @y,           Gosu::Color.argb(0xffffffff),
			@x + @width, @y + @height, Gosu::Color.argb(0xffffffff),
			@x,          @y + @height, Gosu::Color.argb(0xffffffff),
			ZOrder::UI
		)
	end

	private

	def change_images(base_image, hover_image)
		@base_image, @hover_image = base_image, hover_image
	end
end



class TextButton
	attr_reader :width, :height

	def initialize(text, size=24)
		@text = text

		@font = Gosu::Font.new(size, name: "#{ROOT_PATH}/assets/fonts/Dosis.ttf")

		@x = @y = 0.0

		@min_width = @font.text_width(text) + 8
		@width = @min_width
		@height = size + 8

		@hover = false
	end

	def width=(new_width)
		@width = new_width > @min_width ? new_width : @min_width
	end

	def warp(x, y)
		@x, @y = x, y
	end

	def check_hover(mouse_x, mouse_y)
		@x_collide = @x < mouse_x && @x + @width > mouse_x
		@y_collide = @y < mouse_y && @y + @height > mouse_y
		@hover = @x_collide && @y_collide
		@hover
	end

	def hover? = @hover

	def click; end

	def draw
		left_pad = (@width - @min_width + 8) / 2

		if @hover
			Gosu::draw_quad(
				@x,          @y,           Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				@x + @width, @y,           Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				@x + @width, @y + @height, Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				@x,          @y + @height, Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				ZOrder::UI
			)

			@font.draw_text(
				@text,
				@x + left_pad, @y + 4,
				ZOrder::UI,
				1, 1,
				BUTTON_TEXT_COLOUR
			)
		else
			Gosu::draw_quad(
				@x,          @y,           Gosu::Color.argb(BUTTON_SCIM_COLOUR),
				@x + @width, @y,           Gosu::Color.argb(BUTTON_SCIM_COLOUR),
				@x + @width, @y + @height, Gosu::Color.argb(BUTTON_SCIM_COLOUR),
				@x,          @y + @height, Gosu::Color.argb(BUTTON_SCIM_COLOUR),
				ZOrder::UI
			)

			Gosu::draw_line(
				@x,          @y, Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				@x + @width, @y, Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				ZOrder::UI
			)

			Gosu::draw_line(
				@x + @width, @y,           Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				@x + @width, @y + @height, Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				ZOrder::UI
			)

			Gosu::draw_line(
				@x + @width, @y + @height, Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				@x,          @y + @height, Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				ZOrder::UI
			)

			Gosu::draw_line(
				@x, @y + @height, Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				@x, @y,           Gosu::Color.argb(BUTTON_LIFT_COLOUR),
				ZOrder::UI
			)

			@font.draw_text(
				@text,
				@x + left_pad, @y + 4,
				ZOrder::UI,
				1, 1,
				BUTTON_LIFT_COLOUR
			)
		end
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
