#!/usr/bin/ruby

require 'yaml'
require './port_parser.rb'
require './calendar.rb'

CONFIG_FILE = "config.yml"

cfg = YAML.load(File.open(CONFIG_FILE))

# get coming events from Google calendar
calendar = GoogleCal.new(cfg['calendar_id'], cfg['credential_store_file'])
events = calendar.get_arrival_events

# get arriving ships
parser = PortParser.new(cfg['port_uri'])
ships = parser.get_ships()

# update Google calendar
calendar.handle_ships(ships, events)
