require "gosu"
require "yaml"

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
	attr_reader :x, :y, :width, :height, :score, :average_score, :high_score

	def initialize
		@flap = Gosu::Sample.new("media/flap.wav")
		@die = Gosu::Sample.new("media/die.wav")
		@image = Gosu::Image.new("media/player.png")

		@x = @y = @vel_y = @angle = 0.0
		@score = 0
		@width = @image.width
		@height = @image.height
		@high_score, @average_score, @num_runs = get_data
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
		@flap.play
		@vel_y = 5.5
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
		@die.play
		@average_score = (@average_score * @num_runs + @score) / (@num_runs + 1).to_f
		@num_runs += 1
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

	def get_data
		return [0, 0, 0] unless File.file?("data/data.yaml")
		data = YAML.load_file("data/data.yaml")
		[data[:high_score], data[:average_score], data[:num_runs]]
	end

	def save_data
		begin
			File.open("data/data.yaml")
		rescue Errno::ENOENT
			Dir.mkdir("data")
		end

		File.open("data/data.yaml", "w") do |file|
			file.write({
				high_score: @high_score,
				average_score: @average_score,
				num_runs: @num_runs
			}.to_yaml)
		end
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



class Floor
	attr_reader :y, :image

	def initialize
		@image = Gosu::Image.new("media/floor.png")
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





class Game < Gosu::Window
	def initialize
		super Background::IMAGE.width, Background::IMAGE.height, fullscreen: true
		self.caption = "Jumpy Cactus"

		@heading = Gosu::Font.new(50)
		@paragraph = Gosu::Font.new(20)
		@score_text = Gosu::Font.new(35)

		@floor = Floor.new
		@floor.warp(0, Background::IMAGE.height - @floor.image.height)

		@player = Player.new
		@player.reset

		@pipes = []
		@next_pipe = 0

		@home_screen = true
		@playing = false
		@key_released = true
		@freeze_floor = false
		@start_spin = false
		@continue_spin = false

		@gap_height = 150

		@speed = 1.0
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

			if @floor.y - @player.y <= 50 || not_within_gap
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

			if @pipes.length == 0 || @pipes[-1][0].x < Background::IMAGE.width / 2
				new_down_pipe = Pipe.new("down")
				new_up_pipe = Pipe.new("up")
				gap_center = rand(100..(Background::IMAGE.height - 150))

				new_down_pipe.warp(Background::IMAGE.width, gap_center - new_down_pipe.image.height - @gap_height/2)
				new_up_pipe.warp(Background::IMAGE.width, gap_center + @gap_height/2)

				@pipes << [new_down_pipe, new_up_pipe]
			end

			@pipes.reject! { |pair| pair[0].x + pair[0].width <= 0 }
			@pipes.each do |pair|
				pair[0].move(@speed)
				pair[1].move(@speed)
				if @player.x > pair[0].x + pair[0].width && !pair[0].passed_player
					pair[0].passed_player = pair[1].passed_player = true
					@player.increase_score
				end
			end
		end
	end

	def draw
		Background.draw(0, 0, ZOrder::BACKGROUND)

		if @home_screen
			@score_text.draw_text("High score: #{@player.high_score}", 15, 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@score_text.draw_text("Average score: #{@player.average_score.round(2)}", 15, 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@score_text.draw_text("FLAPTUS", Background::IMAGE.width / 2 - 100, Background::IMAGE.height / 2 - 25, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@paragraph.draw_text("Click or press spacebar to play", Background::IMAGE.width / 2 - 142.5, Background::IMAGE.height / 2 + 25, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
		end


		@floor.move(@speed) unless @freeze_floor
		@floor.draw

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
				@speed = 1.0
			end
		elsif @playing
			@player.draw
			@speed += 0.00075
		end
	end

	def button_down(id)
		if id == Gosu::KB_ESCAPE
			@player.save_data
			close
		else
			super
		end
	end
end

Game.new.show
