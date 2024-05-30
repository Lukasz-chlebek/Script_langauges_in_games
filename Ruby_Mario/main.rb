require 'ruby2d'

set title: "Mario w Ruby 2D", width: 800, height: 600

GRID_SIZE = 20
GRAVITY = 1
JUMP_POWER = 15
MOVE_SPEED = 5

class Player
  attr_reader :x, :y, :width, :height

  def initialize
    @x = 50
    @y = 300
    @width = 20
    @height = 20
    @velocity_y = 0
    @on_ground = false
  end

  def draw
    Square.new(x: @x, y: @y, size: @width, color: 'blue')
  end

  def move_left
    @x -= MOVE_SPEED if @x - MOVE_SPEED >= 0
  end

  def move_right
    @x += MOVE_SPEED if @x + MOVE_SPEED < Window.width
  end

  def jump
    if @on_ground
      @velocity_y = -JUMP_POWER
      @on_ground = false
    end
  end

  def apply_gravity
    @velocity_y += GRAVITY
    @y += @velocity_y
  end

  def update(obstacles, holes)
    apply_gravity
    check_collisions(obstacles, holes)
  end

  def check_collisions(obstacles, holes)
    @on_ground = false
    
    obstacles.each do |obs|
      if @x < obs[:x] + obs[:width] && @x + @width > obs[:x] && @y < obs[:y] + obs[:height] && @y + @height > obs[:y]
        if @y + @height - @velocity_y <= obs[:y]
          @y = obs[:y] - @height
          @velocity_y = 0
          @on_ground = true
        elsif @y >= obs[:y] + obs[:height] - @velocity_y
          @y = obs[:y] + obs[:height]
          @velocity_y = 0
        elsif @x + @width - MOVE_SPEED <= obs[:x]
          @x = obs[:x] - @width
        elsif @x >= obs[:x] + obs[:width] - MOVE_SPEED
          @x = obs[:x] + obs[:width]
        end
      end
    end

    if @y + @height >= Window.height - 20 
      @y = Window.height - 20 - @height
      @velocity_y = 0
      @on_ground = true
    end

    holes.each do |hole|
      if @x >= hole[:x] && @x + @width <= hole[:x] + hole[:width] && @y + @height >= hole[:y] && @y <= hole[:y] + hole[:height]
        reset_position
      end
    end
  end

  def reset_position
    @x = 50
    @y = 300
    @velocity_y = 0
    @on_ground = false
  end
end

class Obstacle
  attr_reader :x, :y, :width, :height

  def initialize(x, y, width, height, color)
    @x = x
    @y = y
    @width = width
    @height = height
    @color = color
  end

  def draw
    Rectangle.new(x: @x, y: @y, width: @width, height: @height, color: @color)
  end
end

player = Player.new

obstacles = [
  { x: 100, y: 560, width: 100, height: 20, color: 'red' },
  { x: 150, y: 540, width: 50, height: 20, color: 'red' },
  { x: 300, y: 450, width: 150, height: 20, color: 'red' },
  { x: 700, y: 560, width: 50, height: 20, color: 'red' },
  { x: 750, y: 520, width: 50, height: 20, color: 'red' },
  { x: 550, y: 450, width: 100, height: 20, color: 'red' },
  { x: 120, y: 350, width: 120, height: 20, color: 'red' }
]

holes = [
  { x: 250, y: 580, width: 100, height: 20, color: 'black' },
  { x: 550, y: 580, width: 100, height: 20, color: 'black' }
]

keys_pressed = { left: false, right: false }

update do
  clear

  Rectangle.new(x: 0, y: 580, width: Window.width, height: 20, color: 'green')

  obstacles.each do |obs|
    Rectangle.new(x: obs[:x], y: obs[:y], width: obs[:width], height: obs[:height], color: obs[:color])
  end

  holes.each do |hole|
    Rectangle.new(x: hole[:x], y: hole[:y], width: hole[:width], height: hole[:height], color: hole[:color])
  end

  player.move_left if keys_pressed[:left]
  player.move_right if keys_pressed[:right]

  player.draw
  player.update(obstacles, holes)
end

on :key_down do |event|
  case event.key
  when 'left'
    keys_pressed[:left] = true
  when 'right'
    keys_pressed[:right] = true
  when 'space'
    player.jump
  end
end

on :key_up do |event|
  case event.key
  when 'left'
    keys_pressed[:left] = false
  when 'right'
    keys_pressed[:right] = false
  end
end

show
