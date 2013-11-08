#!/usr/bin/env ruby
require "yaml"
require "ostruct"
require_relative "node"
require_relative "player"
require_relative "utilities"

class TestClass < OpenStruct
  def print_open_value
    # Should call TestClass#open, but it will
    # call Kernel#open after it's loaded from
    # YAML
    puts open
  end

  # Uncomment this method to see the
  # solution in action.
  def init_with(c)
    c.map.keys.each do|k|
      instance_variable_set("@#{k}", c.map[k])
    end

    @table.keys.each do|k|
      new_ostruct_member(k)
    end
  end
end

# This will work
t1 = TestClass.new
t1.open = "A test value"
t1.print_open_value

# This will fail without init_with
t2 = YAML::load( t1.to_yaml )
t2.print_open_value

root = Node.root do
        room(:living_room) do
          self.exit_north = :kitchen
          self.exit_east = :hall

          item(:cat, 'cat', 'sleeping', 'fuzzy') do
            item(:dead_mouse, 'mouse', 'dead', 'eaten')
          end

          item(:remote_control, 'remote', 'control') do
            item(:dead_batteries, 'batteries', 'dead', 'AA')
          end
        end

        room(:kitchen) do
          self.exit_south = :living_room

          player do
            item(:ham_sandwich, 'sandwich', 'ham')
          end
          
          item(:drawer, 'drawer', 'kitchen') do
            item(:new_batteries, 'batteries', 'new', 'AA')
          end
        end

        room(:hall) do
          self.exit_west = :living_room
        end
      end

loop do
  player = root.find(:player)
  player.do_look
  
  %x[ #{'say What now'} ]
  input = gets.chomp
  verb = input.split(' ').first

  case verb
  when "load"
    root = Node.load
    puts "Loaded"
  when "save"
    Node.save(root)
    puts "Saved"
  when "quit"
    puts "Goodbye!"
    exit
  else
    player.command(input)
  end
end