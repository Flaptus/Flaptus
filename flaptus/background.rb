module Background
	IMAGE = Gosu::Image.new("#{ROOT_PATH}/assets/images/background.png", tileable: false)

	def self.draw(x, y, z)
		IMAGE.draw(x, y, z)
	end
end
