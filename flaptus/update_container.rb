class UpdateContainer
	attr_reader :width, :height, :x, :y

	def initialize(current, new)
		@current, @new = current, new
		@background = Gosu::Image.new("#{ROOT_PATH}/assets/images/update_prompt_container.png")

		@x = @y = 0.0

		@width  = @background.width
		@height = @background.height

		@big_text    = Gosu::Font.new(60, name: "#{ROOT_PATH}/assets/fonts/Sniglet.ttf")
		@medium_text = Gosu::Font.new(43, name: "#{ROOT_PATH}/assets/fonts/Sniglet.ttf")
		@small_text  = Gosu::Font.new(35, name: "#{ROOT_PATH}/assets/fonts/Sniglet.ttf")
	end

	def warp(x, y)
		@x, @y = x, y
	end

	def draw
		@background.draw(@x, @y, ZOrder::UI)
		
		@big_text.draw_text("Update Detected!", @x + 10, @y + 20, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
		@medium_text.draw_text("Current version: #{@current}", @x + 10, @y + 100, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
		@medium_text.draw_text("Newer version: #{@new}", @x + 10, @y + 150, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
		@small_text.draw_text("Would you like to update?", @x + 10, @y + @height - 150, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
	end
end
