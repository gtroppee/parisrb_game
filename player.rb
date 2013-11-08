class Player < Node
  def command(words)
    verb, *words = words.split(' ')
    verb = "do_#{verb}"

    if respond_to?(verb)
      send(verb, *words)
    else
      puts "I don't know how to do that"
    end
  end

  def do_go(direction, *a)
    dest = get_room.send("exit_#{direction}")

    if dest.nil?
      puts 'You cannot go that way'
      %x[ #{'say You cannot go that way'} ]
    else
      dest = get_root.find(dest)

      if dest.script('enter', direction)
        get_root.move(self, dest)
      end
    end

    room(:hall) do
      self.exit_west = :living_room

      self.script_enter = <<-SCRIPT
        puts "A forcefield stops you from entering the hall"
        return false
      SCRIPT
    end
  end

  def do_examine(*thing)
    item = get_room.find(thing)
    return if item.nil?

    item.described = false
    item.describe
  end

  def do_inventory(*a)
    puts "You are carrying:"

    if children.empty?
      puts " * Nothing"
    else
      children.each do|c|
        puts " * #{c.short_description} (#{c.words.join(' ')})"
      end
    end
  end
  alias_method :do_inv, :do_inventory
  alias_method :do_i, :do_inventory

  def do_take(*thing)
    thing = get_room.find(thing)
    return if thing.nil?

    if thing.script('take')
      puts 'Taken.' if get_root.move(thing, self)
    end

    item(:cat, 'cat', 'sleeping', 'fuzzy') do
      self.script_take = <<-SCRIPT
        if find(:dead_mouse)
          puts "The cat makes a horrifying noise and throws up a dead mouse"
          get_room.move(:dead_mouse, get_room, false)
        end

        puts "The cat refused to be picked up (how degrading!)"
        return false
      SCRIPT

      self.script_control = <<-SCRIPT
        puts "The cat sits upright, awaiting your command"
        return true
      SCRIPT

      self.desc = <<-DESC
        A pumpkin-colored long-haired cat.  He is well-groomed
        and certainly a house cat and seems perfectly content
        to sleep the day away on the couch.
      DESC

      self.short_desc = <<-DESC
        A pumpkin-colored long-haired cat.
      DESC

      self.presence = <<-PRES
        A cat dozes lazily here.
      PRES

      item(:dead_mouse, 'mouse', 'dead', 'eaten')
    end
  end
  alias_method :do_get, :do_take

  def do_drop(*thing)
    move(thing.join(' '), get_room)
  end

  def open_close(thing, state)
    container = get_room.find(thing)
    return if container.nil?
    
    if container.open == state
      puts "It's already #{state ? 'open' : 'closed'}"
    else
      container.open = state
    end
  end

  def do_open(*thing)
    open_close(thing, true)
  end

  def do_close(*thing)
    open_close(thing, false)
  end

  def do_look(*a)
    puts "You are in #{get_room.tag}"
  end

  def do_inventory(*a)
    puts "You are carrying:"

    if children.empty?
      puts " * Nothing"
    else
      children.each do|c|
        puts " * #{c.name} (#{c.words.join(' ')})"
      end
    end
  end

  def do_put(*words)
    prepositions = [' in ', ' on ']

    prep_regex = Regexp.new("(#{prepositions.join('|')})")
    item_words, _, cont_words = words.join(' ').split(prep_regex)

    if cont_words.nil?
      puts "You want to put what where?"
      return
    end

    item = get_room.find(item_words)
    container = get_room.find(cont_words)

    return if item.nil? || container.nil?

    if container.script('accept', item)
      get_room.move(item, container)
    end

    item(:remote_control, 'remote', 'control') do
      self.script_accept = <<-SCRIPT
        if [:new_batteries, :dead_batteries].include?(args[0].tag) &&
            children.empty?
          return true
        elsif !children.empty?
          puts "There are already batteries in the remote"
          return false
        else
          puts "That won't fit into the remote"
          return false
        end
      SCRIPT

      self.script_use = <<-SCRIPT
        if !find(:new_batteries)
          puts "The remote doesn't seem to work"
          return
        end

        if args[0].tag == :cat
          args[0].script('control')
          return
        else
          puts "The remote doesn't seem to work with that"
          return
        end
      SCRIPT

      item(:dead_batteries, 'batteries', 'dead', 'AA')
    end
  end

  %w{ north south east west up down }.each do|dir|
    define_method("do_#{dir}") do
      do_go(dir)
    end

    define_method("do_#{dir[0]}") do
      do_go(dir)
    end
  end
  alias_method :do_get, :do_take
  alias_method :do_inv, :do_inventory
  alias_method :do_i, :do_inventory

  def do_use(*words)
    prepositions = %w{ in on with }
    prepositions.map!{|p| " #{p} " }

    prep_regex = Regexp.new("(#{prepositions.join('|')})")
    item1_words, _, item2_words = words.join(' ').split(prep_regex)

    if item2_words.nil?
      puts "I don't quite understand you"
      return
    end

    item1 = get_room.find(item1_words)
    item2 = get_room.find(item2_words)
    return if item1.nil? || item2.nil?

    item1.script('use', item2)
  end

  def play
    loop do
      do_look
      print "What now? "
      command(gets.chomp)
    end
  end

end