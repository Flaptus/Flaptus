require "gosu"

module ZOrder
	BACKGROUND, PIPES, FLOOR, PLAYER, UI = *0...5
end


module Background
	IMAGE = Gosu::Image.new("media/background.png", tileable: false)

	def self.draw(x, y, z)
		IMAGE.draw(x, y, z)
	end
end




class Player
	attr_reader :x, :y, :width, :height, :score, :high_score

	def initialize
		@image = Gosu::Image.new("media/player.png")
		@x = @y = @vel_y = @angle = 0.0
		@score = @high_score = 0
		@width = @image.width
		@height = @image.height
	end

	def reset
		@x = 150
		@y = 200
		@score = 0
		@vel_y = @angle = 0.0
	end

	def warp(x, y)
		@x, @y = x, y
	end

	def jump
		@vel_y = 5.0
	end

	def move
		@vel_y = -2 if @y <= 0
		@y -= @vel_y
		@vel_y -= 0.2
	end

	def increase_score
		@score += 1
			@high_score = @score if @score > @high_score
	end

	def start_death_spin
		@angle = 0.0
		@vel_y = 5.0
		death_spin
	end

	def death_spin
		@y -= @vel_y
		@vel_y -= 0.25
		@angle += 7.5
		@image.draw_rot(@x, @y, ZOrder::PLAYER, @angle)
	end

	def draw
		@image.draw(@x, @y, ZOrder::PLAYER)
	end
end



class Pipe
	attr_reader :image, :x, :width
	attr_accessor :passed_player

	def initialize(direction)
		@image = Gosu::Image.new("media/pipe_#{direction}.png")
		@x = @y = 0.0
		@height = @image.height
		@width = @image.width
		@passed_player = false
	end

	def warp(x, y)
		@x, @y = x, y
	end

	def move
		@x -= 2
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



class Floor
	attr_reader :y, :image

	def initialize
		@image = Gosu::Image.new("media/floor.png")
		@x = @y = 0.0
	end

	def warp(x, y)
		@x, @y = x, y
	end

	def move
		@x -= 2
		@x = Background::IMAGE.width if @x + @image.width <= 0
	end

	def draw
		@image.draw(@x, @y, ZOrder::FLOOR)
	end
end





class Game < Gosu::Window
	def initialize
		super Background::IMAGE.width, Background::IMAGE.height, fullscreen: true
		self.caption = "Jumpy Cactus"

		@heading = Gosu::Font.new(50)
		@paragraph = Gosu::Font.new(20)
		@score_text = Gosu::Font.new(35)

		@floor_tiles = []
		for tile_num in 0..(Background::IMAGE.width / Floor.new.image.width)
			tile = Floor.new
			tile.warp(tile.image.width * tile_num, Background::IMAGE.height - tile.image.height)
			@floor_tiles << tile
		end

		@player = Player.new
		@player.reset

		@pipes = []

		@home_screen = true
		@playing = false
		@key_released = true
		@freeze_floor = false
		@start_spin = false
		@continue_spin = false

		@frame_count = 0
		@gap_height = 150
	end

	def update
		if @home_screen
			if (Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT)) && @key_released
				@key_released = false
				@home_screen = false
				@playing = true
				@player.reset
				@pipes = []
			elsif !(Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT))
				@key_released = true
			end
		elsif @playing
			pipes_within_x = @pipes[0..1].select { |pair| pair[0].within_x?(@player) }
			not_within_gap = pipes_within_x.length == 1 ? !pipes_within_x[0][0].within_gap_y?(@player, @gap_height) : false

			if @floor_tiles[0].y - @player.y <= 50 || not_within_gap
				@start_spin = true
				@freeze_floor = true
				@playing = false
				return
			elsif (Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT)) && @key_released
				@key_released = false
				@player.jump
			elsif !(Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT))
				@key_released = true
			end
			@player.move


			if @frame_count % 150 == 0
				new_down_pipe = Pipe.new("down")
				new_up_pipe = Pipe.new("up")
				gap_center = rand(100..Background::IMAGE.height - 150)

				new_down_pipe.warp(Background::IMAGE.width, gap_center - new_down_pipe.image.height - @gap_height/2)
				new_up_pipe.warp(Background::IMAGE.width, gap_center + @gap_height/2)

				@pipes << [new_down_pipe, new_up_pipe]
			end

			@pipes.reject! { |pair| pair[0].x + pair[0].width <= 0 }
			@pipes.each do |pair|
				pair[0].move
				pair[1].move
				if @player.x > pair[0].x + pair[0].width && !pair[0].passed_player
					pair[0].passed_player = pair[1].passed_player = true
					@player.increase_score
				end
			end
		end
	end

	def draw
		@frame_count += 1

		Background.draw(0, 0, ZOrder::BACKGROUND)

		if @home_screen
			@score_text.draw_text("High score: #{@player.high_score}", 15, 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@score_text.draw_text("FLAPTUS", Background::IMAGE.width / 2 - 100, Background::IMAGE.height / 2 - 25, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@paragraph.draw_text("Click or press spacebar to play", Background::IMAGE.width / 2 - 142.5, Background::IMAGE.height / 2 + 25, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
		end

		@floor_tiles.each do |tile|
			tile.move unless @freeze_floor
			tile.draw
		end

		if @playing || @start_spin || @continue_spin
			@pipes.each do |pair|
				pair[0].draw
				pair[1].draw
			end

			@score_text.draw_text("High score:	#{@player.high_score}", 15, 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@score_text.draw_text("Current score: #{@player.score}", 15, 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
		end

		if @start_spin
			@player.start_death_spin
			@start_spin = false
			@continue_spin = true
		elsif @continue_spin
			@player.death_spin
			if Background::IMAGE.height - @player.y <= 0
				@continue_spin = false
				@home_screen = true
				@freeze_floor = false
			end
		elsif @playing
			@player.draw
		end
	end

	def button_down(id)
		if id == Gosu::KB_ESCAPE
			close
		else
			super
		end
	end
end

Game.new.show
