
class Integer
	HEXMAP = {0=>'0',1=>'1',2=>'2',3=>'3',4=>'4',5=>'5',6=>'6',7=>'7',8=>'8',9=>'9',10=>'a',11=>'b',12=>'c',13=>'d',14=>'e',15=>'f'}
	def to_hex_slow
		#raise "to_hex only supports 2-digit hexidecimal numbers (< 256)" if self > 255
		big = self / 16
		small = self - (big*16)
		"#{HEXMAP[big]}#{HEXMAP[small]}"
	end
	
	def to_hex_fast
		#str = "%0.2x" % self
		#str = "0#{str}" unless str.size % 2 == 0
		#str
		"%0.2x" % self
	end
		
	def to_hex; to_hex_fast; end
end

def benchmark
	iterations 		= 500000
	max 					= 255
	
	[:to_hex_slow, :to_hex_fast].each do |method|
		start = Time.now
		iterations.times { rand(max).send method }
		elapsed = Time.now - start
		puts "#{iterations} #{method}s in #{elapsed}s"
	end
end

if $0 == __FILE__
	testnums = [10, 15, 23, 254]
	10.times { testnums << rand(1<<32) }
	testnums.each { |num| puts "#{num} => #{num.to_hex}" }
	benchmark
end
