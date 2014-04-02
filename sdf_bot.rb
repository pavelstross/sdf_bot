#!/usr/bin/env ruby

require 'cinch'

require 'nokogiri'
require 'open-uri'

bot = Cinch::Bot.new do
  configure do |c|
    c.nick = "sdf_bot"
    c.server = "euroserv.fr.quakenet.org"
    c.channels = ["#sDF"]
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

bot.start
