#!/usr/bin/env ruby

require 'cinch'

require 'nokogiri'
require 'open-uri'

require 'rubygems'
require 'sqlite3'
require 'active_record'


ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Schema.define do
  create_table "servers", :force => true do |t|
    t.column "name", :string
    t.column "map", :string
    t.column "address", :string
  end
  create_table "players", :force => true do |t|
    t.column "name", :string
    t.column :server_id, :integer    
  end

end

class Player < ActiveRecord::Base
  belongs_to :Servers
end

class Server < ActiveRecord::Base
  has_many :Players
end

def fetch_and_parse_data
  doc = Nokogiri::HTML(open('http://dpmaster.deathmask.net/?game=openarena'))
  indexes = []
  doc.xpath("//div[@id='gametype']").drop(1).each_with_index do |gametype, index|
    if gametype.text == "defrag" then
       indexes.push(index)
    end
  end
  puts "#{indexes}"
  server_names = doc.xpath("//div[@id='name']").drop(1)
  server_address = doc.xpath("//div[@id='address']").drop(1)
  server_maps = doc.xpath("//div[@id='map']").drop(1)
  indexes.each do |index|
    Server.create(:id => index, :name => server_names.fetch(index).text, :map => server_maps.fetch(index).text, :address => server_address.fetch(index).text)
    players = doc.xpath("//div[@id='players_#{server_address.fetch(index).text}']/div[@id='handle']").drop(1)
    players.each do |p|
      Player.create(:name => p.text, :server_id => index)
    end
  end
end

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = "sdf_bot_test"
    c.server = "euroserv.fr.quakenet.org"
    c.channels = ["#sdf_bot_test"]
  end

  on :message, "!help" do |m|
    m.reply "Available options:\n !players - Current players on the server\n"
  end
  on :message, "!players" do |m|
    doc = Nokogiri::HTML(open('http://dpmaster.deathmask.net/?game=openarena&server=195.154.82.77:27960'))
    replytext = "Current players on sDF server: \n"
    doc.xpath("//div[@id='handle']").drop(1).each do |p|
      replytext = replytext + "\t#{p.text} \n"
    end
    m.reply replytext
  end
end

#
#Thread.fork {
#    while true
#      puts 'forked thread'
#      sleep(3)
#    end
#}


#bot.start
