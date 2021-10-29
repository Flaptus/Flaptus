class Player
	attr_reader :x, :y, :width, :height, :score, :average_score, :high_score

	def initialize
		@flap = Gosu::Sample.new("#{ROOT_PATH}/assets/audio/flap.wav")
		@die = Gosu::Sample.new("#{ROOT_PATH}/assets/audio/die.wav")
		@image = Gosu::Image.new("#{ROOT_PATH}/assets/images/flaptus.png")
		@image_flap = Gosu::Image.new("#{ROOT_PATH}/assets/images/flaptus_flap.png")

		@flapping = 0
		@x = @y = @vel_y = @angle = 0.0
		@score = 0
		@width = @image.width
		@height = @image.height
		@high_score, @average_score, @num_runs = get_data
		@sfx_muted = false
	end

	def set_sfx_muted(muted)
		@sfx_muted = muted
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

	def flap
		if !@sfx_muted
			@flap.play
		end

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
		if !@sfx_muted
			@die.play
		end

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

	def get_data
		return [0, 0, 0] unless File.file?("flaptus_data/data.yaml")
		data = YAML.load_file("flaptus_data/data.yaml")
		[data[:high_score], data[:average_score], data[:num_runs]]
	end

	def save_data
		begin
			File.open("flaptus_data/data.yaml")
		rescue Errno::ENOENT
			Dir.mkdir("flaptus_data")
		end

		File.open("flaptus_data/data.yaml", "w") do |file|
			file.write({
				high_score: @high_score,
				average_score: @average_score,
				num_runs: @num_runs
			}.to_yaml)
		end
	end
end
