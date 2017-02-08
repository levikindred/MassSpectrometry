#This program accepts the reformatted mass spectrometry data and
#creates a smoothed heat map of the data with mass/charge ratio (mz)
#along the x axis and intensity along the y axis

filePath = ARGV[0]
data = Array.new(0)
mz_min = 1000000
mz_max = 0
rt_min = 1000000
rt_max = 0

#go through the file finding the maximum and minimum
#bin values for mz and rt
File.open(filePath) do |file|
	file.each do |line|
		nums = line.split(",")
		mz = (nums[0].chop.to_f * 10.0).to_i
		if (mz > mz_max)
			mz_max = mz
		end
		if (mz < mz_min)
			mz_min = mz
		end
		rt = (nums[1].chop.to_f * 1.0).to_i
		if (rt > rt_max)
			rt_max = rt
		end
		if (rt < rt_min)
			rt_min = rt
		end
	end
end

mz_range = mz_max - mz_min
rt_range = rt_max - rt_min

logInten = Array.new(mz_range + 1) {Array.new(rt_range + 1) {0}}

#this is the code that smooths the map
#the mask looks like this
#  .05 .05 .05
#  .05 .60 .05
#  .05 .05 .05
File.open(filePath) do |file|
	file.each do |line|
		nums = line.split(",")
		mz = (nums[0].chop.to_f * 10.0).to_i
		x = mz - mz_min
		rt = (nums[1].chop.to_f * 1.0).to_i
		y = rt - rt_min
		point = nums[2].chop.to_f
		logInten[x][y] += 0.6 * point
		if (x > 0)
			logInten[x - 1][y] += 0.05 * point
			if (y > 0)
				logInten[x - 1][y - 1] += 0.05 * point
			end
			if (y < rt_range)
				logInten[x - 1][y + 1] += 0.05 * point
			end
		end
		if (x < mz_range)
			logInten[x + 1][y] += 0.05 * point
			if (y > 0)
				logInten[x + 1][y - 1] += 0.05 * point
			end
			if (y < rt_range)
				logInten[x + 1][y + 1] += 0.05 * point
			end
		end
		if (y > 0)
			logInten[x][y - 1] += 0.05 * point
		end
		if (y < rt_range)
			logInten[x][y + 1] += 0.05 * point
		end
	end
end

inten_min = 1000000
inten_max = 0

#now we go through the array replacing the values with their logarithm
logInten.each_index do |x|
	logInten[x].each_index do |y|
		point = logInten[x][y]
		if (point != 0)
			point = Math.log(point)
			logInten[x][y] = point
		end
		if (point < inten_min)
			inten_min = point
		end
		if (point > inten_max)
			inten_max = point
		end
	end
end

inten_range = inten_max - inten_min

legendW = 50
outfile = File.open("map.svg","w")
outfile.puts "<svg width=\"#{mz_range + legendW + 1}\" height=\"#{rt_range + 1}\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink= \"http://www.w3.org/1999/xlink\">"

logInten.each_index do |x|
	logInten[x].each_index do |y|
		outfile.puts "<rect x=\"#{mz_range - x}\" y=\"#{rt_range - y}\" width=\"1\" height=\"1\" style=\"fill:rgb(#{(255 * (logInten[x][y] - inten_min)/inten_range).to_i},0,#{255 - (255 * (logInten[x][y] - inten_min)/inten_range).to_i});\" />"
	end
end

logInten[0].each_index do |y|
	outfile.puts "<rect x=\"#{mz_range + 1}\" y=\"#{y}\" width=\"#{legendW}\" height=\"1\" style=\"fill:rgb(#{255 - (255 * y/rt_range)},0,#{255 * y/rt_range});\" />"
end

outfile.puts "</svg>"
outfile.close