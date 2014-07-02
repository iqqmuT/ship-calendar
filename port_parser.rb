#!/usr/bin/ruby

require 'nokogiri'
require 'open-uri'
require './ship.rb'

class PortParser

  def initialize(uri)
    @uri = URI(uri)
  end

  def get_ships
    doc = Nokogiri::HTML(open(@uri))
    # xpath for getting rows
    xpath = '//html/body/table/tr[2]/td/table/tr[position() > 2]'
    rows = doc.xpath(xpath)
    ships = []
    rows.each do |row|
      ships << handle_row(row)
    end
    ships
  end

  def handle_row(row)
    ship = Ship.new
    i = 0
    row.children.each do |td|
      case i
        when 0
          elems = td.children()[0].children()
          ship.updated = elems_to_time(elems)
        when 1
          ship.vessel = td.content
        when 2
          ship.nationality = td.content
        when 3
          ship.from = td.children()[0].content
          ship.to = td.children()[2].content
        when 4
          elems = td.children()[0].children()
          ship.eta = elems_to_time(elems)
        when 5
          ship.berth = td.content
        when 6
          elems = td.children()[0].children()
          ship.ets = elems_to_time(elems)
      end
      i = i + 1
    end
    #puts ship.to_s
    ship
  end

  def elems_to_time(elems)
    d = elems[0].content.split('.')
    t = elems[2].content.split(':')
    Time.new('20' + d[2], d[1], d[0], t[0], t[1])
  end
end
