class Leaderboard
	PAGE_LENGTH = 10
	COLUMN_WIDTH = 150

	attr_reader :width, :height, :x, :y, :page

	def initialize
		@background = Gosu::Image.new("#{ROOT_PATH}/assets/images/leaderboard.png")

		@x = @y = 0.0

		@width  = @background.width
		@height = @background.height

		@big_font   = Gosu::Font.new(50, name: "#{ROOT_PATH}/assets/fonts/Dosis.ttf")
		@small_font = Gosu::Font.new(30, name: "#{ROOT_PATH}/assets/fonts/Dosis.ttf")
		@page_font  = Gosu::Font.new(25, name: "#{ROOT_PATH}/assets/fonts/Dosis.ttf")

		@page = 1
		@scores = []
	end

	def warp(x, y)
		@x, @y, = x, y
	end

	def change_page(direction)
		new_page = @page + direction
		if new_page > 0 && new_page <= (@scores.length/PAGE_LENGTH.to_f).ceil
			@page += direction
			Thread.new { @scores = JSON.parse(URI.open("https://leaderboard.flaptus.com/api/leaderboard").read) }
		end
	end

	def open
		Thread.new { @scores = JSON.parse(URI.open("https://leaderboard.flaptus.com/api/leaderboard").read) }
		@page = 1
	end

	def page_text
		"Page #{@page} of #{(@scores.length/PAGE_LENGTH.to_f).ceil}"
	end

	def page_text_width
		@page_font.text_width(page_text)
	end

	def draw
		@background.draw(@x, @y, ZOrder::UI)

		padding_left = (@width - COLUMN_WIDTH * 3) / 2.0

		@big_font.draw_text("Rank",  @x + padding_left + (COLUMN_WIDTH - @big_font.text_width("Rank")) / 2.0,                     @y + 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
		@big_font.draw_text("Name",  @x + padding_left + COLUMN_WIDTH + (COLUMN_WIDTH - @big_font.text_width("Name")) / 2.0,      @y + 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
		@big_font.draw_text("Score", @x + padding_left + COLUMN_WIDTH * 2 + (COLUMN_WIDTH - @big_font.text_width("Score")) / 2.0, @y + 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)

		padding_top = 15 + @big_font.height
		@scores[(PAGE_LENGTH * (@page-1))...(PAGE_LENGTH * @page)].each_with_index do |score, index|
			@small_font.draw_text("#{index+1 + PAGE_LENGTH*(@page-1)}.",     @x + padding_left + (COLUMN_WIDTH - @small_font.text_width("#{index+1}.")) / 2.0,                     @y + padding_top + @small_font.height * index, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
			@small_font.draw_text(score["username"], @x + padding_left + COLUMN_WIDTH + (COLUMN_WIDTH - @small_font.text_width(score["username"])) / 2.0,  @y + padding_top + @small_font.height * index, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
			@small_font.draw_text(score["score"],    @x + padding_left + COLUMN_WIDTH * 2 + (COLUMN_WIDTH - @small_font.text_width(score["score"])) / 2.0, @y + padding_top + @small_font.height * index, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
		end

		@page_font.draw_text(page_text, @x + @width/2.0 - page_text_width/2.0, @y + @height - @page_font.height - 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
	end
end
