#!/usr/bin/env ruby


require 'rubygems'
require 'thread'

require 'sqlite3'
require 'active_record'

require 'nokogiri'
require 'open-uri'

require 'cinch'
require 'cinch/commands'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => ':memory:'
)

class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil
 
  def self.connection
    @@shared_connection || retrieve_connection
  end
end
 
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection

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

class SdfBotPlugin 
  include Cinch::Plugin
  include Cinch::Commands

  command :players
 
  def players(m)
    replyText = ""
    Player.all.each do |p|
	 replyText = replyText + "#{p.name}]" + " plays on server #{Server.find(p.server_id).name}\n"
    end
    m.reply(replyText)
  end
end


def fetch_and_parse_data
  doc = Nokogiri::HTML(open('http://dpmaster.deathmask.net/?game=openarena'))
  indexes = []
  doc.xpath("//div[@id='gametype']").drop(1).each_with_index do |gametype, index|
    if gametype.text == "defrag" then
       indexes.push(index)
    end
  end
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
    c.nick = "sDF_BOT"
    c.server = "euroserv.fr.quakenet.org"
    c.channels = ["#sdf"]
    c.plugins.plugins = [SdfBotPlugin]
  end
end


fetcher = Thread.new {
    while true
      Player.destroy_all
      Server.destroy_all
      fetch_and_parse_data
      sleep(30)
    end
}

bot.start
fetcher.join
