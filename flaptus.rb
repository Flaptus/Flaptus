VERSION   = "1.3.1"
ROOT_PATH = File.expand_path(".", __dir__)
REPO_URL  = "https://github.com/Coding-Cactus/Flaptus"
VOLUME    = 0.75

require "gosu"
require "yaml"
require "open-uri"

require_relative "#{ROOT_PATH}/flaptus/pipe.rb"
require_relative "#{ROOT_PATH}/flaptus/floor.rb"
require_relative "#{ROOT_PATH}/flaptus/player.rb"
require_relative "#{ROOT_PATH}/flaptus/buttons.rb"
require_relative "#{ROOT_PATH}/flaptus/foreground.rb"
require_relative "#{ROOT_PATH}/flaptus/background.rb"
require_relative "#{ROOT_PATH}/flaptus/update_container.rb"


# delete old exe if it still exists
begin
	File.delete("flaptus-old.exe")
rescue Errno::ENOENT
end

module ZOrder
	BACKGROUND, FOREGROUND, PIPES, FLOOR, PLAYER, UI = *0...6
end



class Game < Gosu::Window
	def initialize
		super Background::IMAGE.width, Background::IMAGE.height
		self.caption = "Flaptus"


		@speed        = 1.0
		@pipes        = []
		@next_pipe    = 0
		@gap_height   = 150
		@game_state   = :home_screen
		@key_released = true

		@background_music = Gosu::Song.new("#{ROOT_PATH}/assets/audio/WHEN_THE_CAC_IS_TUS.mp3")
		@background_music.volume = VOLUME

		@heading    = Gosu::Font.new(100, name: "#{ROOT_PATH}/assets/fonts/Jumpman.ttf")
		@paragraph  = Gosu::Font.new(30, name: "#{ROOT_PATH}/assets/fonts/Jumpman.ttf")
		@score_text = Gosu::Font.new(45, name: "#{ROOT_PATH}/assets/fonts/Jumpman.ttf")


		@floor = Floor.new
		@floor.warp(0, Background::IMAGE.height - @floor.image.height)

		@foreground = Foreground.new
		@background = Background.new

		@player = Player.new
		@player.reset


		begin
			URI.open("#{REPO_URL}/releases/latest") { |f| @latest_version = f.base_uri.to_s.split("/v")[1] }
			@game_state = :request_update if @latest_version != VERSION
		rescue
			# no internet connection
		end

		@update_container = UpdateContainer.new(VERSION, @latest_version)
		@update_container.warp(
			(Background::IMAGE.width - @update_container.width) / 2,
			(Background::IMAGE.height - @update_container.height) / 2
		)

		@no_update  = NoButton.new
		@yes_update = YesButton.new

		@no_update.warp(
			@update_container.x + 20,
			@update_container.y + @update_container.height - @no_update.height - 20
		)
		@yes_update.warp(
			@update_container.x + @update_container.width - @yes_update.width - 20,
			@update_container.y + @update_container.height - @yes_update.height - 20
		)


		@fullscreen_button = FullScreenButton.new
		@fullscreen_button.warp(Background::IMAGE.width - @fullscreen_button.width - 20, 20)

		if @player.fullscreen?
			@fullscreen_button.click
			self.fullscreen = true
		end

		@mute_button = MuteButton.new
		@mute_button.warp(Background::IMAGE.width - @mute_button.width - @fullscreen_button.width - 40, 20)

		if @player.mute?
			@mute_button.click
			@background_music.volume = 0.0
		end

		@sfx_button = SfxButton.new
		@sfx_button.warp(Background::IMAGE.width - @sfx_button.width - @mute_button.width - @fullscreen_button.width - 60, 20)

		if !@player.sfx?
			@sfx_button.click
		end

		@home_screen_buttons = [
			@fullscreen_button,
			@mute_button,
			@sfx_button
		]


		@background_music.play(true)
	end

	def update
		case @game_state
		when :request_update
			@no_update.check_hover(self.mouse_x, self.mouse_y)
			@yes_update.check_hover(self.mouse_x, self.mouse_y)

			if Gosu.button_down?(Gosu::MS_LEFT) && @key_released
				@key_released = false

				if @no_update.hover?
					@game_state = :home_screen
				elsif @yes_update.hover?
					File.rename("flaptus.exe", "flaptus-old.exe")

					File.open("flaptus.exe", "w") {}
					download = URI.open("#{REPO_URL}/releases/download/v#{@latest_version}/flaptus.exe")
					IO.copy_stream(download, "flaptus.exe")

					pid = spawn "flaptus"
					Process.detach(pid)
					close
				end
			elsif !(Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT))
				@key_released = true
			end

		when :home_screen
			@home_screen_buttons.each { |button| button.check_hover(self.mouse_x, self.mouse_y) }

			if (Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT)) && @key_released
				@key_released = false

				if @fullscreen_button.hover?
					@fullscreen_button.click
					@player.fullscreen = !@player.fullscreen?
					self.fullscreen = @player.fullscreen?

				elsif @mute_button.hover?
					@mute_button.click
					@player.mute = !@player.mute?

					if @player.mute?
						@background_music.volume = 0.0
					else
						@background_music.volume = VOLUME
					end

				elsif @sfx_button.hover?
					@sfx_button.click
					@player.sfx = !@player.sfx?
					
				else
					@game_state = :playing
					@player.reset
					@pipes = []
				end
			elsif !(Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT))
				@key_released = true
			end

			@floor.move(@speed)
			@foreground.move(@speed)
			@background.move(@speed)

		when :playing
			pipes_within_x = @pipes[0..1].select { |pair| pair[0].within_x?(@player) }
			not_within_gap = pipes_within_x.length == 1 ? !pipes_within_x[0][0].within_gap_y?(@player, @gap_height) : false

			if @player.y + @player.height >= @floor.y || not_within_gap
				@game_state = :start_death
				return
			elsif (Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT)) && @key_released
				@key_released = false
				@player.flap
			elsif !(Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT))
				@key_released = true
			end

			@player.move
			@floor.move(@speed)
			@foreground.move(@speed)
			@background.move(@speed)

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
		case @game_state
		when :home_screen, :request_update
			@score_text.draw_text("High score: #{@player.high_score}", 15, 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@score_text.draw_text("Average score: #{@player.average_score.round(2)}", 15, 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@heading.draw_text("FLAPTUS", Background::IMAGE.width / 2 - 125, Background::IMAGE.height / 2 - 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@paragraph.draw_text("Click or press spacebar to play", Background::IMAGE.width / 2 - 175, Background::IMAGE.height / 2 + 35, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)

			@home_screen_buttons.each { |button| button.draw }

			if @game_state == :request_update
				@update_container.draw
				@no_update.draw
				@yes_update.draw
			end

		when :playing, :start_death, :dying
			@score_text.draw_text("High score: #{@player.high_score}", 15, 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)
			@score_text.draw_text("Current score: #{@player.score}", 15, 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::GREEN)

			@pipes.each do |pair|
				pair[0].draw
				pair[1].draw
			end

			case @game_state
			when :playing
				@player.draw
				@speed += 0.00075

			when :start_death
				@background_music.pause
				Thread.new do
					sleep 1.75
					@background_music.play(true)
				end

				@player.start_death_spin
				@game_state = :dying

			when :dying
				@player.death_spin

				if Background::IMAGE.height - @player.y <= 0
					@game_state = :home_screen
					@speed = 1.0
				end
			end
		end

		# in every game state
		@floor.draw
		@foreground.draw
		@background.draw
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
