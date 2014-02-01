# Runetic Test
# Chad Godsey
# Oct 29, 2008

require 'rubygems'
require 'gosu'
require 'caruby'
require '../lib/runetic.rb'

##
## Our Game Window
##
class BatchProcess

	@@vecx = [0,-1,-1,-1,0,1,1,1]
	@@vecy = [-1,-1,0,1,1,1,0,-1]
	
	attr_reader :decays, :spreadMax, :spread, :spreadCount, :avgDecays, :maxDecays
	
	def initialize

		@Automaton = CellularAutomata::Automaton.load('prototype_01.rb')
		@bugs = @Automaton.grids[:PLAYER1] 
		
		@decay = @Automaton.states[4]

		@pattern = Array.new(3) { Array.new(3) { |e| rand(4) } }
		
		# Set pattern
		@bugs.each {|r| r.each { |c| c.set(@Automaton.states[0]) } }
		(10...13).each { |r|
			(10...13).each { |c|
				@bugs[r][c].set(@Automaton.states[@pattern[r-10][c-10]])
			}
		}
		
		@count = 0
		@countsub = 0
		
		@timer = 0
	end
	
	##
	##
	def fitness
		if @fitness.nil?
			@fitness = 0
			@spread = 0
			@spreadMax = 0
			@spreadCount = 0
			@decays = 0
			@avgDecays = 0
			@maxDecays = 0
			(1..100).each do |iter|
				#inspection
				@Automaton.each_cell(:PLAYER1) { |cell,x,y|
					for i in 0...8
						unless (x+@@vecx[i])%@bugs.size != (x+@@vecx[i])  or
							(y+@@vecy[i])%@bugs[0].size != (y+@@vecy[i])
							v = @bugs[(x+@@vecx[i])][(y+@@vecy[i])]
							cell.addSurround v
						end
					end
				}
			
				lastDecays = @decays
				#enact rule output
				@Automaton.each_cell(:PLAYER1) { |cell,x,y|
					react = cell.surround
					trans = @Automaton.NextState(cell, react)
					if trans and trans.to == @decay
						@decays += 1
						#distance squared
						d = ((x-12)**2 + (y-12)**2)**0.5
						@spreadMax = d if d > @spreadMax
						@spread += d / (Math.log(iter*2) + 1.0)
					end
					cell.reset
					cell.set trans.to if trans
				}
				curDecays = @decays-lastDecays
				@maxDecays = curDecays if curDecays > @maxDecays
			end
			@avgDecays = @decays/100
			@decays = 1 if @decays.zero?
			@fitness = @spread/@decays + @decays/2.0 + @spreadMax + @maxDecays + 10*@avgDecays
		end
		@fitness
	end
	
	##
	##
	def reset
		@fitness = nil
		# Set pattern
		@bugs.each {|r| r.each { |c| c.set(@Automaton.states[0]) } }
		(10...12).each { |r|
			(10...12).each { |c|
				@bugs[r][c].set(@Automaton.states[@pattern[r-10][c-10]])
			}
		}
	end
	
	##
	##
	def dclone
		chromosome = BatchProcess.new
		@pattern.each_index { |r|
			@pattern[r].each_index { |c|
				chromosome[r*3 + c] = @pattern[r][c]
			}
		}
		chromosome
	end
		
	def [](index)
		@pattern[index/3][index%3]
	end
	
	def []=(index,object)
		@pattern[index/3][index%3] = object
		reset
	end
	
	def flip(index)
		@pattern[index/3][index%3] = (@pattern[index/3][index%3]+1)%3
		reset
	end
	
	def length
		9
	end
	
	def to_s
		strs = []
		strs << "Fitness: " + @fitness.to_s
		@pattern.each_index { |r|
			sub = "["
			@pattern[r].each_index { |c|
				sub += @pattern[r][c].to_s + ", "
			}
			sub += "],"
			strs << sub
		}
		strs
	end
	
end



#Test ourself if this is the current file and not an include
if __FILE__ == $0
	(1..20).each { |i|
		ga = Runetic::Algorithm.new(20, 0.9, 0.2, 1, BatchProcess, Runetic::RouletteSelection, Runetic::TwoPoint, Runetic::FlipMask)
		
		file = File.new("batch_mini_" + i.to_s + ".txt", File::CREAT|File::TRUNC|File::RDWR)
		(1..20).each { |i| 
			ga.solve 
			file.puts ga.best.to_s + " " + ga.worst.to_s
		}
		file.puts "Best: " + ga.best.to_s
		file.puts "Worst: " + ga.worst.to_s
		file.puts "Population:"
		ga.population.each { |c| 
			file.puts c.to_s 
			file.puts ""
		}
		file.close
	}
end