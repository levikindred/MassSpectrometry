#This program accepts an mzXML file as input and parses through
#the data converting the base 64 numbers into floating point
#numbers and saving the data as a csv containing the mass/charge
#ratio (mz), time of the scan, and intensity sorted by mz or intensity

require "base64"
unless ARGV.size() == 1 or ARGV.size() == 3
	puts "Incorrect number of arguments."
	exit
end
filePath = ARGV[0]
$contents = ""
unless File.file?(filePath)
	puts "Incorrect file argument."
	exit
end
IO.foreach(filePath) {|x| $contents << x }


def findNextArrayLength()
	dist = $contents =~ /defaultArrayLength="/
	if dist == nil
		return nil
	end
	$contents = $contents[dist + 20..-1]
	dist = $contents =~ /"/
	num = $contents[0..dist - 1]
	return num.to_i
end

def isNextMs1()
	dist = $contents =~ /name="ms level" value="/
	$contents = $contents[dist + 23..-1]
	dist = $contents =~ /"/
	num = $contents[0..dist - 1]
	return num.to_i
end

def findScanTime()
	dist = $contents =~ /name="scan start time" value="/
	$contents = $contents[dist + 30..-1]
	dist = $contents =~ /"/
	num = $contents[0..dist - 1]
	return num.to_f
end

def getData()
	dist = $contents =~ /<binary>/
	$contents = $contents[dist + 8..-1]
	dist = $contents =~ /</
	num = $contents[0..dist - 1]
	return Base64.decode64(num)
end

table = []

while(true)
	length = findNextArrayLength()
	if (length == nil)
		break
	end
	if (isNextMs1 != 1)
		next
	end
	time = findScanTime()
	mz = getData().unpack("d*")
	inten = getData().unpack("f*")
	temp = 0
	while (length > temp)
		table.push([mz[temp],time,inten[temp]])
		temp += 1
	end
end

if (ARGV.size() > 2)
	if (ARGV[2] == "-mz")
		table.sort!{|x, y| x[0] <=> y[0]}
	end
	if (ARGV[2] == "-rt")
		table.sort!{|x, y| x[1] <=> y[1]}
	end
end

outfile = File.open("output.csv","w")
table.each do |data|
	outfile.puts "#{format("%.4f", data[0])},#{format("%.4f", data[1])},#{format("%.4f", data[2])}"
end
outfile.close