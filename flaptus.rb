VERSION   = "1.6.0"
ROOT_PATH = File.expand_path(".", __dir__)
REPO_URL  = "https://github.com/Flaptus/Flaptus"
VOLUME    = 0.75
WIDTH     = 833
HEIGHT    = 511

THEME_COLOUR = 0xff_2d832d
TEXT_COLOUR  = 0xff_eeffee

# builds: replace this with the secret value
SECRET    = ENV["SECRET"]

if !SECRET
	puts "No secret environment variable found, this will break the leaderboard functionality."
end

require "gosu"
require "yaml"
require "json"
require "open-uri"
require "net/http"

require_relative "#{ROOT_PATH}/flaptus/rock.rb"
require_relative "#{ROOT_PATH}/flaptus/scrim.rb"
require_relative "#{ROOT_PATH}/flaptus/floor.rb"
require_relative "#{ROOT_PATH}/flaptus/player.rb"
require_relative "#{ROOT_PATH}/flaptus/buttons.rb"
require_relative "#{ROOT_PATH}/flaptus/textbox.rb"
require_relative "#{ROOT_PATH}/flaptus/foreground.rb"
require_relative "#{ROOT_PATH}/flaptus/background.rb"
require_relative "#{ROOT_PATH}/flaptus/leaderboard.rb"
require_relative "#{ROOT_PATH}/flaptus/update_container.rb"


# delete old exe if it still exists
begin
	File.delete("flaptus-old.exe")
rescue Errno::ENOENT
end

module ZOrder
	BACKGROUND, FOREGROUND, ROCKS, FLOOR, PLAYER, UI = *0...6
end



class Game < Gosu::Window
	def initialize
		super WIDTH, HEIGHT
		self.caption = "Flaptus"


		@speed        = 1.0
		@rocks        = []
		@next_rock    = 0
		@text_input   = nil
		@gap_height   = 150
		@game_state   = :home_screen
		@key_released = true

		@background_music = Gosu::Song.new("#{ROOT_PATH}/assets/audio/WHEN_THE_CAC_IS_TUS.mp3")
		@background_music.volume = VOLUME

		@heading    = Gosu::Font.new(100, name: "#{ROOT_PATH}/assets/fonts/Jumpman.ttf")
		@subheading = Gosu::Font.new(25,  name: "#{ROOT_PATH}/assets/fonts/Jumpman.ttf")

		@paragraph  = Gosu::Font.new(30,  name: "#{ROOT_PATH}/assets/fonts/Dosis.ttf")
		@score_text = Gosu::Font.new(30,  name: "#{ROOT_PATH}/assets/fonts/Dosis.ttf")


		@floor = Floor.new
		@floor.warp(0, HEIGHT - @floor.image.height)

		@foreground = Foreground.new
		@background = Background.new
		
		@scrim = Scrim.new

		@player = Player.new
		@player.reset

		@internet_connection = true
		begin
			URI.open("#{REPO_URL}/releases/latest") { |f| @latest_version = f.base_uri.to_s.split("/v")[1] }
			@game_state = :request_update if @latest_version != VERSION
		rescue
			@internet_connection = false
		end

		@update_container = UpdateContainer.new(VERSION, @latest_version)
		@update_container.warp(
			(WIDTH - @update_container.width) / 2,
			(HEIGHT - @update_container.height) / 2
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
		@fullscreen_button.resize(50, 50)
		@fullscreen_button.warp(WIDTH - @fullscreen_button.width - 20, 20)

		if @player.fullscreen?
			@fullscreen_button.click
			self.fullscreen = true
		end

		@mute_button = MuteButton.new
		@mute_button.resize(50, 50)
		@mute_button.warp(WIDTH - @mute_button.width - @fullscreen_button.width - 40, 20)

		if @player.mute?
			@mute_button.click
			@background_music.volume = 0.0
		end

		@sfx_button = SfxButton.new
		@sfx_button.resize(50, 50)
		@sfx_button.warp(WIDTH - @sfx_button.width - @mute_button.width - @fullscreen_button.width - 60, 20)

		if !@player.sfx?
			@sfx_button.click
		end

		@home_screen_buttons = [
			@fullscreen_button,
			@mute_button,
			@sfx_button
		]

		@quit_button = TextButton.new("Quit", 32)
		@button_stack = [
			TextButton.new("Play", 32),
			@quit_button
		]

		if @internet_connection
			if !@player.authed? && !!SECRET
				@signup_button = TextButton.new("Sign up", 32)
				@button_stack.push(@signup_button) # :'(
			end

			@leaderboard_button = TextButton.new("Leaderboard", 32)
			@button_stack.insert(1, @leaderboard_button)

			@leaderboard = Leaderboard.new
			@leaderboard.warp((WIDTH - @leaderboard.width) / 2.0, (HEIGHT - @leaderboard.height) / 2.0)

			@leaderboard_close_button = CloseButton.new
			@leaderboard_close_button.warp(@leaderboard.width + (WIDTH - @leaderboard.width)/2.0 - @leaderboard_close_button.width - 10, (HEIGHT - @leaderboard.height)/2.0 + 10)

			@leaderboard_left_button = LeftArrowButton.new
			@leaderboard_left_button.warp(
				@leaderboard.x + @leaderboard.width/2.0 - @leaderboard.page_text_width/2.0 - @leaderboard_left_button.width - 10,
				@leaderboard.y + @leaderboard.height - @leaderboard_left_button.height - 10
			)

			@leaderboard_right_button = RightArrowButton.new
			@leaderboard_right_button.warp(
				@leaderboard.x + @leaderboard.width/2.0 + @leaderboard.page_text_width/2.0 + 10,
				@leaderboard.y + @leaderboard.height - @leaderboard_right_button.height - 10
			)
		end

		stack_width = @button_stack.collect {|button| button.width}.max + 32
		stack_x = (WIDTH - stack_width) / 2
		stack_y = 250

		for button in @button_stack
			button.width = stack_width
			button.warp(stack_x, stack_y)

			stack_y += button.height + 8
		end

		@home_screen_buttons += @button_stack

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

		when :signup
			@submit_button.check_hover(self.mouse_x, self.mouse_y)
			@cancel_button.check_hover(self.mouse_x, self.mouse_y)

			if Gosu.button_down?(Gosu::MS_LEFT) && @key_released
				@key_released = false

				self.text_input = @username_field.hover?(self.mouse_x, self.mouse_y) ? @username_field : nil
				self.text_input.move_caret(self.mouse_x) unless self.text_input == nil

				if @submit_button.hover?
					Thread.new do
						res_code = nil

						begin
							r = Net::HTTP.post_form(
								URI.parse("https://leaderboard.flaptus.com/api/newuser"),
								{
									secret:   SECRET,
									username: @username_field.text
								}
							)

							res_code = r.code
						rescue
						end

						if res_code == "200"
							@game_state      = :home_screen
							@player.token    = r.body
							@player.username = @username_field.text

							@home_screen_buttons.reject! { |button| button == @signup_button }
						else
							@signup_error = r.body
						end
					end
				elsif @cancel_button.hover?
					@game_state   = :home_screen
					@signup_error = nil
				end
			elsif !(Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT))
				@key_released = true
			end

		when :leaderboard
			@leaderboard_close_button.check_hover(self.mouse_x, self.mouse_y)
			@leaderboard_left_button.check_hover(self.mouse_x, self.mouse_y)
			@leaderboard_right_button.check_hover(self.mouse_x, self.mouse_y)

			if Gosu.button_down?(Gosu::MS_LEFT) && @key_released
				@key_released = false

				if @leaderboard_close_button.hover?
					@game_state   = :home_screen
				elsif @leaderboard_left_button.hover?
					@leaderboard.change_page(-1)
				elsif @leaderboard_right_button.hover?
					@leaderboard.change_page(1)
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
					self.fullscreen    = @player.fullscreen?

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

				elsif @internet_connection && @leaderboard_button.hover?
					@game_state = :leaderboard
					@leaderboard.open

				elsif @signup_button != nil && @internet_connection && !@player.authed? && @signup_button.hover?
					@game_state = :signup

					@username_field = TextBox.new(self, placeholder: "Username")

					@submit_button = TextButton.new("Submit", 32)
					@submit_button.width = @username_field.width

					@cancel_button = TextButton.new("Cancel", 32)
					@cancel_button.width = @username_field.width
				
				elsif @quit_button.hover?
					close

				else
					@rocks      = []
					@game_state = :playing
					@player.reset

				end
			elsif !(Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT))
				@key_released = true
			end

		when :playing
			rocks_within_x = @rocks[0..1].select { |pair| pair[0].within_x?(@player) }
			not_within_gap = rocks_within_x.length == 1 ? !rocks_within_x[0][0].within_gap_y?(@player, @gap_height) : false

			if @player.y + @player.height >= @floor.y || not_within_gap
				@game_state = :start_death

				if @internet_connection && @player.authed?
					Thread.new do
						res_code = nil

						begin
							r = Net::HTTP.post_form(
								URI.parse("https://leaderboard.flaptus.com/api/newscore"),
								{
									secret: SECRET,
									token:  @player.token,
									score:  @player.score
								}
							)

							res_code = r.code
						rescue
						end

						if res_code != "200"
							puts "Server returned error on score submission"
							#close
						end
					end
				end

				return
			elsif (Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT)) && @key_released
				@key_released = false
				@player.flap
			elsif !(Gosu.button_down?(Gosu::KB_SPACE) || Gosu.button_down?(Gosu::MS_LEFT))
				@key_released = true
			end

			@player.move

			if @rocks.length == 0 || @rocks[-1][0].x < WIDTH / 2
				new_up_rock   = Rock.new("up")
				new_down_rock = Rock.new("down")
				gap_center    = rand(100..(HEIGHT - 150))

				new_down_rock.warp(WIDTH, gap_center - new_down_rock.image.height - @gap_height/2)
				new_up_rock.warp(WIDTH,   gap_center + @gap_height/2)

				@rocks << [new_down_rock, new_up_rock]
			end

			@rocks.reject! { |pair| pair[0].x + pair[0].width <= 0 }
			@rocks.each do |pair|
				pair[0].move(@speed)
				pair[1].move(@speed)
				if @player.x > pair[0].x + pair[0].width && !pair[0].passed_player
					pair[0].passed_player = pair[1].passed_player = true
					@player.increase_score
				end
			end
		end


		unless @game_state == :dying || @game_state == :start_death
			@floor.move(@speed)
			@foreground.move(@speed)
			@background.move(@speed)
		end
	end

	def draw
		case @game_state
		when :home_screen, :request_update, :signup, :leaderboard
			@score_text.draw_text(
				"High score: #{@player.high_score}",
				15, 15, ZOrder::UI,
				1.0, 1.0,
				Gosu::Color.argb(TEXT_COLOUR)
			)
			@score_text.draw_text(
				"Average score: #{@player.average_score.round(2)}",
				15, 45, ZOrder::UI,
				1.0, 1.0,
				Gosu::Color.argb(TEXT_COLOUR)
			)

			heading_x = (WIDTH - @heading.text_width("FLAPTUS")) / 2

			@heading.draw_text(
				"FLAPTUS",
				heading_x, 105, ZOrder::UI,
				1.0, 1.0,
				Gosu::Color.argb(THEME_COLOUR)
			)
			@subheading.draw_text(
				"CODINGCACTUS'S",
				heading_x, 95, ZOrder::UI,
				1.0, 1.0,
				Gosu::Color.argb(THEME_COLOUR)
			)

			if @game_state != :signup
				logged_in = @internet_connection && @player.authed?
				login_text = logged_in ? @player.username : "Offline"
				login_x = (WIDTH - @score_text.text_width(login_text)) / 2
	
				@score_text.draw_text(
					login_text,
					login_x, 205, ZOrder::UI,
					1.0, 1.0,
					Gosu::Color.argb(THEME_COLOUR)
				)

				@home_screen_buttons.each { |button| button.draw }
			end

			case @game_state
			when :request_update
				@update_container.draw
				@no_update.draw
				@yes_update.draw

			when :signup
				stux = (WIDTH - @score_text.text_width("Sign up")) / 2
				@score_text.draw_text(
					"Sign up",
					stux, 205, ZOrder::UI,
					1.0, 1.0,
					Gosu::Color.argb(THEME_COLOUR)
				)

				common_x = (WIDTH - @username_field.width) / 2

				@username_field.warp(common_x, 250)
				@username_field.draw

				offset_x = common_x + @username_field.width / 2 + 8
				button_w = @username_field.width / 2 - 4

				@submit_button.width = button_w
				@submit_button.warp(common_x, 258 + @username_field.height)
				@submit_button.draw

				@cancel_button.width = button_w
				@cancel_button.warp(offset_x, 258 + @username_field.height)
				@cancel_button.draw

				if @signup_error
					@paragraph.draw_text(
						@signup_error,
						(WIDTH - @paragraph.text_width(@signup_error)) / 2,
						266 + @username_field.height + @submit_button.height,
						ZOrder::UI,
						1.0, 1.0,
						Gosu::Color::RED
					)
				end

			when :leaderboard
				@scrim.draw
				@leaderboard.draw
				@leaderboard_close_button.draw
				@leaderboard_left_button.draw
				@leaderboard_right_button.draw
			end

		when :playing, :start_death, :dying
			@score_text.draw_text("High score: #{@player.high_score}", 15, 15, ZOrder::UI, 1.0, 1.0, Gosu::Color.argb(TEXT_COLOUR))
			@score_text.draw_text("Current score: #{@player.score}", 15, 50, ZOrder::UI, 1.0, 1.0, Gosu::Color.argb(TEXT_COLOUR))

			@rocks.each do |pair|
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

				if HEIGHT - @player.y <= 0
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
