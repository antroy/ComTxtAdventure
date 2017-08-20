#!/usr/bin/env ruby

require 'yaml'

class Character
    attr_accessor :charinfo
    def initialize(charinfo)
        @charinfo = charinfo #character yaml file
    end
    def change_name
        puts "Character name? => " #input text
        @name = gets.chomp #get input

        @charinfo[:name] = @name #Modify
        File.open('characters.yaml', 'w') {|f| f.write @charinfo.to_yaml } 
        puts "Hello #{@name}" #show to player the name
    end
    def inventory
        puts "Inventory:"
        for item in @charinfo['items'] 
            puts "#{item['name']}"
        end
    end
end

class Room
    def initialize(general_info, roominfo=default_room_info())
        @roominfo = roominfo
        @general_info = general_info
    end
    def default_room_info
        data = {
            1 => {:name => "Starting Room", :items => {"Starting Sword" => {:type => "Weapon"}}, :npcs => {"NONE" => {:type => "NONE"}}, :exits => {"Hallway" => "NORTH"}, :in? => true},
            2 => {:name => "Hallway", :items => {"Potion" => {:type => "Consumable"}}, :npcs => {"Goblin" => {:type => "enemy"}}, :exits => {"Throne Room" => "WEST", "Starting Room" => "SOUTH"}, :in? => false}
        }
        File.open("roominfo.yaml", "w") {|f| f.write(data.to_yaml) }
        roominfo = YAML::load_file('roominfo.yaml')
        return roominfo
    end
    def move(dir)
        goingto = ""
        breakk = false
        @roominfo.each do |key, value|
            if key == @general_info["current_room"]
                value[:in?] = false
                value[:exits].each do |k, v|
                    if v == dir 
                        goingto = k
                        puts "You go #{dir}"
                    end
                end

                breakk = true
                @roominfo.each do |k, v|
                    v.each do |ke, val|
                        if ke.to_s() == "name" 
                            if val.to_s() == goingto.to_s()
                                v[:in?] = true
                                @general_info["current_room"] = k
                                File.open('general_info.yaml', 'w') {|f| f.write @general_info.to_yaml } 
                            end
                        end
                    end
                end
            end
            break if breakk == true      
        end
    end
    def room_in_desc
        @roominfo.each do |key, value|
            if key == @general_info["current_room"]
                puts "You are in the #{value[:name]}"
                value[:items].each do |k, v|
                    puts "Items in this room: #{k}"
                end
                value[:npcs].each do |k, v|
                    puts "Npcs in this room: #{k}"
                end
            end
        end
    end
end

class Game
    def initialize
        @character
        @room
        @quit = false
    end
    def init_game
        puts "New Game or Load Game? (NEW / LOAD) => "
        gametype = gets.chomp
        if gametype.upcase == "NEW" #creates new info for the yml for new game
            data = {:name => "NAME", :health => "100", :items => {:name => "Flashlight"}}
            data2 = {"current_room" => 1}
            File.open("characters.yaml", "w") {|f| f.write(data.to_yaml) }
            charinfo = YAML::load_file('characters.yaml')
            File.open("general_info.yaml", "w") {|f| f.write(data2.to_yaml) }
            general_info = YAML::load_file("general_info.yaml")
            @character = Character.new(charinfo)
            @character.change_name()
            @room = Room.new(general_info)
            true
        elsif gametype.upcase == "LOAD" #does the same thing as NEW but puts past data by loading
            begin
                charinfo = YAML::load(File.open('characters.yaml')) 
            rescue ArgumentError => e #just in case
                  puts "Could not parse CHARACTER YAML: #{e.message}"
            end
            @character = Character.new(charinfo)

            begin 
                roominfo = YAML::load(File.open('roominfo.yaml'))
            rescue ArgumentError => e
                puts "Could not parse ROOM YAML: #{e.message}"
            end
            begin 
                general_info = YAML::load(File.open('general_info.yaml'))
            rescue ArgumentError => e
                puts "Could not parse GENERAL YAML: #{e.message}"
            end
            @room = Room.new(general_info, roominfo)
            false
        else
            puts ""
            puts "Invalid Input Option"
            puts "Quitting!"
            abort
        end
    end
    def game_loop
        while true do
            command_test()
            abort if @quit == true
        end
    end
    def command_test()
        print "=> "
        command = gets.chomp.upcase
        save_game() if command == "SAVE"
        load_game() if command == "LOAD"
        @room.room_in_desc() if command == "ROOM"
        @room.move("NORTH") if command == "NORTH" 
        @room.move("SOUTH") if command == "SOUTH"
        @room.move("EAST") if command == "EAST"
        @room.move("WEST") if command == "WEST"
        @character.inventory() if command == "INVENTORY"
        if command == "EXAMINE"
            puts "Which item? "
            item = gets.chomp
            @character.examine(item.lowercase) 
        end
        @quit = true if command == "QUIT" 
    end
    def start_game
        puts "You wake up in an empty room"
        puts "#{@character.charinfo['name']} => Where am I?"
        puts "You see a door to the north of the room"
        puts "Would you like a tutorial? (Y/n) "
        tut = gets.chomp
        if tut.upcase == "Y"
            puts "Running tutorial..."
            tutorial()
            game_loop()
        elsif tut.upcase == "N"
            puts "Ok!"
            game_loop()
        end
    end
end

game = Game.new
option = game.init_game()
if option == true
    game.start_game 
elsif option == false
    puts ""
    puts "You wake up back where you were..."
    game.game_loop
end
