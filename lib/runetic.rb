## = Runetic Algorithm - Genetic Algorithms for Ruby
## == Author
## Chad Godsey
## Oct 27, 2008
## == License
## Runetic is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Runetic is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
##
##
## == About
##	Runetic is meant to provide a simple interface to build Genetic Algorithms
##	with Ruby


module Runetic

	##
	##
	##
	class Algorithm
		attr_reader :population, :highFit, :lowFit, :populationSize, :probMutate, :probCross, :generation
		
		def initialize( popSize = 100, pX = 0.9, pM = 0.1, elites = 0, chromClass = Chromosome, selection = RouletteSelection, crossover = OnePoint, mutate = FlipRand)
			@populationSize, @elites, @probMutate, @probCross = popSize, elites, pM, pX
			@highFit = @lowFit = 0
			@selection = selection
			@crossover = crossover
			@mutate = mutate
			
			@generation = 0
			
			@population = Array.new(@populationSize) { |c| chromClass.new() }
			@population.map! { |c| [c, c.fitness] }
			@population.sort! { |a,b| b[1] <=> a[1] }
			@population.map! { |c| c[0] }
		end
		
		
		def solve 
			fits = @population.map { |c| c.fitness }
			newGen = @selection.call( @populationSize, @population.zip(fits) )
			
			## cross-over
			i = 0
			while i < newGen.length
				if rand < @probCross
					@crossover.call( newGen[i], newGen[i+1] )
				end
				i += 2
			end
			## mutation
			for c in newGen
				if rand < @probMutate
					@mutate.call( c )
				end
			end
			newGen.map! { |c| [c, c.fitness] }
			newGen.sort! { |a,b| b[1] <=> a[1] }
			newGen.map! { |c| c[0] } 
			## Elites do not mutate or cross-over
			##	this method is some sort of abortion, btw
			(0...@elites).each { |e|
				newGen[-(e+1)] = @population[e]
			}
			unless @elites.zero?
				newGen.map! { |c| [c, c.fitness] }
				newGen.sort! { |a,b| b[1] <=> a[1] }
				newGen.map! { |c| c[0] } 
			end
			@population = newGen
			@generation += 1
			
			
			##	Inspection stuff
			puts "Sum: " + (fits.inject(0) { |m,o| m += o }).to_s + " Best: " + @population[0].fitness.to_s
			
		end
		
		def best
			@population[0].fitness
		end
		
		
		def worst
			@population[-1].fitness
		end
	
	end
	
	
	##
	##
	##
	class Chromosome
		def initialize
			@data = Array.new(10) { |e| rand<0.5 ? true : false }
		end
		
		def fitness
			fit = 0
			@data.each { |d| fit += 1 if d }
			fit
		end
		
		def dclone
			chromosome = Chromosome.new
			@data.each_index { |i|
				chromosome[i] = @data[i]
			}
			chromosome
		end
		
		def [](index)
			@data[index]
		end
		
		def []=(index,object)
			@data[index] = object
		end
		
		def flip(index)
			@data[index] = @data[index] ? false : true
		end
		
		def length
			@data.length
		end
	end
	
	
	##
	##	Selection functions
	##
	
	##
	##
	ProportionalSelection = lambda { |num, pop|		
		length = pop[0][0].length
		selection = []
		(1..num).each { |i|
			r = rand
			pick = false
			pop.each { |p|
				if r < p[1]/length.to_f
					selection.push(p[0].dclone)
					pick = true
					break
				end
			}
			selection.push(pop[-1][0].dclone) unless pick
		}
		
		selection
	}
	
	##
	##
	RouletteSelection = lambda { |num, pop|
		sumFit = 0
		for p in pop
			f = p[1]
			p[1] = sumFit + p[1]
			sumFit += f
		end
		
		length = pop[0][0].length
		selection = []
		(1..num).each { |i|
			r = rand(sumFit)
			pop.each { |p|
				if r < p[1]
					selection.push(p[0].dclone)
					break
				end
			}
		}
		
		selection
	}
	
	
	##
	##	Crossover functions
	##
	
	##
	##
	OnePoint = lambda { |ch1, ch2|
		r = rand(ch1.length)
		(0...r).each { |i|
			swap = ch1[i]
			ch1[i] = ch2[i]
			ch2[i] = swap
		}
	}
	
	##
	##
	TwoPoint = lambda { |ch1, ch2|
		r1 = rand(ch1.length)
		r = rand(ch1.length-r1) - r1
		(r1...r).each { |i|
			swap = ch1[i]
			ch1[i] = ch2[i]
			ch2[i] = swap
		}
	}
	
	
	##
	##	Mutation functions
	##
	
	##
	##
	FlipRand = lambda { |chrom|
		r = rand(chrom.length)
		chrom.flip(r)
	}
	
	##
	##
	FlipMask = lambda { |chrom|
		l = chrom.length
		(0...l).each { |i|
			chrom.flip(i) if rand(2)==0
		}
	}
end



#Test ourself if this is the current file and not an include
if __FILE__ == $0
	ga = Runetic::Algorithm.new
	(1..50).each { |i| ga.solve }
	puts "Best: " + ga.best.to_s
	puts "Worst: " + ga.worst.to_s
end