# Runetic Test
# Chad Godsey
# Oct 29, 2008

require 'rubygems'
require 'gosu'
require 'caruby'

##
## Our Game Window
##
class GameWindow < Gosu::Window

	@@squarex = 10
	@@squarey = 10
	@@vecx = [0,-1,-1,-1,0,1,1,1]
	@@vecy = [-1,-1,0,1,1,1,0,-1]
	@@P1_startX = 100
	@@P1_startY = 100
	
	def initialize
		super(640, 480, false, 20)
		self.caption = "iPhone Prototype"
		@bug_image = Gosu::Image.new(self, 'germ.png', true)
		@font = Gosu::Font.new(self, 'Times', 10)

		@Automaton = CellularAutomata::Automaton.load('prototype_01.rb')
		@bugs = @Automaton.grids[:PLAYER1] 
		
		@pattern = [
[1, 1, 0, 2, 1, ],
[3, 1, 1, 1, 1, ],
[1, 1, 2, 0, 2, ],
[0, 0, 1, 1, 0, ],
[2, 1, 2, 2, 1, ]]
		@pattern2 = [
[1, 0, 0, 1, 2, ],
[1, 1, 1, 1, 2, ],
[1, 1, 1, 1, 2, ],
[1, 1, 2, 1, 2, ],
[2, 1, 1, 2, 2, ]]

		# Set pattern
		@bugs.each {|r| r.each { |c| c.set(@Automaton.states[0]) } }
		(10...15).each { |r|
			(10...15).each { |c|
				@bugs[r][c].set(@Automaton.states[@pattern[r-10][c-10]])
			}
		}
=begin
		(5...10).each { |r|
			(5...10).each { |c|
				@bugs[r][c].set(@Automaton.states[@pattern[r-5][c-5]])
			}
		}
		
		(15...20).each { |r|
			(15...20).each { |c|
				@bugs[r][c].set(@Automaton.states[@pattern2[r-15][c-15]])
			}
		}
=end
		@count = 1
		@countsub = 0
		
		@timer = 0
	end
	
	def update
		#Quit if player presses escape
		if button_down? Gosu::Button::KbEscape
			close
		end
		if @count.zero?
			@count = 1
		#inspection
			@Automaton.each_cell(:PLAYER1) { |cell,x,y|
				for i in 0...8
					unless (x+@@vecx[i])%@bugs.size != (x+@@vecx[i])  or
						(y+@@vecy[i])%@bugs[0].size != (y+@@vecy[i])
						v = @bugs[(x+@@vecx[i])%@bugs.size][(y+@@vecy[i])%@bugs[0].size]
						cell.addSurround v
					end
				end
			}

		#rule propagation (?)
		
		#enact rule output
			@Automaton.each_cell(:PLAYER1) { |cell,x,y|
				react = cell.surround
				trans = @Automaton.NextState(cell, react)
				cell.reset
				cell.set trans.to if trans
			}

		end
		@count -= 1
		
		@timer += 1
	end
	
	def draw
		draw_quad( 0, 0, 0xFF000000,
			width, 0, 0xFF000000,
			0, height, 0xFF000000,
			width, height, 0xFF000000, 0)
		
		@Automaton.each_cell(:PLAYER1) { |cell,x,y|
			@bug_image.draw(@@P1_startX + x*@@squarex, 
				@@P1_startY + y*@@squarey, 
				1, 1, 1, cell.state.hexColor)
		}
		
		@font.draw( "Timer: " + @timer.to_s, 10, 10, 1)
	end
end



#Test ourself if this is the current file and not an include
if __FILE__ == $0
	window = GameWindow.new
	window.show
end