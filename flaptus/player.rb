class Player
	attr_reader :x, :y, :width, :height, :score, :average_score, :high_score, :username, :token

	def initialize
		@die        = Gosu::Sample.new("#{ROOT_PATH}/assets/audio/die.wav")
		@flap       = Gosu::Sample.new("#{ROOT_PATH}/assets/audio/flap.wav")
		@image      = Gosu::Image.new("#{ROOT_PATH}/assets/images/flaptus.png")
		@image_flap = Gosu::Image.new("#{ROOT_PATH}/assets/images/flaptus_flap.png")

		@score     = 0
		@width     = @image.width
		@height    = @image.height
		@flapping  = 0

		@x = @y = @vel_y = @angle = 0.0

		@username, @token = get_login_data
		@fullscreen, @sfx, @mute = get_preference_data
		@high_score, @average_score, @num_runs = get_score_data
	end

	def sfx?        = @sfx
	def mute?       = @mute
	def fullscreen? = @fullscreen
	def authed?     = @token != nil

	def fullscreen=(fullscreen)
		@fullscreen = fullscreen
		save_data
	end

	def sfx=(sfx)
		@sfx = sfx
		save_data
	end

	def mute=(mute)
		@mute = mute
		save_data
	end

	def username=(username)
		@username = username
		save_data
	end

	def token=(token)
		@token = token
		save_data
	end

	def reset
		@x     = 150
		@y     = 200
		@score = 0
		@vel_y = @angle = 0.0
	end

	def warp(x, y)
		@x, @y = x, y
	end

	def flap
		@flap.play if @sfx

		@vel_y = 5.5
		@flapping = 4
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
		@die.play if @sfx

		@average_score = (@average_score * @num_runs + @score) / (@num_runs + 1).to_f
		@num_runs += 1
		save_data

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
		(@flapping > 0 ? @image_flap : @image).draw(@x, @y, ZOrder::PLAYER)
		@flapping -= 1 if @flapping > 0
	end

	private

	def get_score_data
		return [0, 0, 0] unless File.file?("flaptus_data/data.yaml")
		data = YAML.load_file("flaptus_data/data.yaml")
		[data[:high_score], data[:average_score], data[:num_runs]]
	end

	def get_preference_data
		return [false, true, false] unless File.file?("flaptus_data/preferences.yaml")

		data = YAML.load_file("flaptus_data/preferences.yaml")
		[data[:fullscreen], data[:sfx], data[:mute]]
	end

	def get_login_data
		return [nil, nil] unless File.file?("flaptus_data/login.yaml")

		data = YAML.load_file("flaptus_data/login.yaml")
		[data[:username], data[:token]]
	end

	def save_data
		begin
			File.open("flaptus_data/data.yaml")
		rescue Errno::ENOENT
			Dir.mkdir("flaptus_data")
		end

		File.open("flaptus_data/login.yaml", "w") do |file|
			file.write({
				token:    @token,
				username: @username
			}.to_yaml)
		end

		File.open("flaptus_data/data.yaml", "w") do |file|
			file.write({
				num_runs:      @num_runs,
				high_score:    @high_score,
				average_score: @average_score
			}.to_yaml)
		end

		File.open("flaptus_data/preferences.yaml", "w") do |file|
			file.write({
				sfx:        @sfx,
				mute:       @mute,
				fullscreen: @fullscreen
			}.to_yaml)
		end
	end
end
