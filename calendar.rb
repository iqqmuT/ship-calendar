#!/usr/bin/ruby

require 'rubygems'
require 'google/api_client'
require 'google/api_client/auth/file_storage'

class GoogleCal

  def initialize(calendar_id, credential_store_file)
    @client = Google::APIClient.new(
      :application_name => 'Ship Calendar',
      :application_version => '1.0.0')
    file_storage = Google::APIClient::FileStorage.new(credential_store_file)
    @client.authorization = file_storage.authorization
    @calendar = @client.discovered_api('calendar', 'v3')
    @calendar_id = calendar_id
  end

  def get_arrival_events
    parameters = {
      'calendarId' => @calendar_id,
      'timeMin' => DateTime.now.to_s
    }
    result = @client.execute(:api_method => @calendar.events.list,
                                :parameters => parameters,
                                :authorization => @client.authorization.dup)
    result.data.items
  end

  def handle_ships(ships, events)
    ships.each do |ship|
      handle_ship(ship, events)
    end

    events.each do |event|
      handle_event(event, ships)
    end
  end

  # If given ship is found from events, update event,
  # else insert new event.
  def handle_ship(ship, events)
    found = false
    events.each do |event|
      if ship.summary === event.summary then
        update_event(ship, event)
        found = true
      end
    end

    if not found then
      insert_event(ship)
    end

  end

  # If given event is not found from ships, delete event.
  def handle_event(event, ships)
    found = false
    ships.each do |ship|
      if event.summary === ship.summary then
        found = true
      end
    end

    if not found then
      if event.start.dateTime > Time.now then
        # delete only if event start is in the future
        delete_event(event)
      end
    end
  end

  # Inserts new ship
  def insert_event(ship)
    puts "INSERT " + ship.summary
    event = {
      'summary' => ship.summary,
      'location' => ship.berth,
      'start' => {
        'dateTime' => time_to_google(ship.eta),
      },
      'end' => {
        'dateTime' => time_to_google(ship.ets),
      },
    }

    # Fetch list of events on the user's default calandar
    result = @client.execute(:api_method => @calendar.events.insert,
                             :parameters => {'calendarId' => @calendar_id},
                             :body => JSON.dump(event),
                             :headers => { 'Content-Type' => 'application/json' },
                             :authorization => @client.authorization.dup)
    #puts result.data.id
  end

  # Updates event
  def update_event(ship, event)
    puts "UPDATE " + ship.summary
    event.summary = ship.summary
    event.location = ship.berth
    event.start.dateTime = time_to_google(ship.eta)
    event.end.dateTime = time_to_google(ship.ets)

    # Update event information
    result = @client.execute(:api_method => @calendar.events.update,
                             :parameters => {
                              'calendarId' => @calendar_id,
                              'eventId' => event.id
                             },
                             :body_object => event,
                             :headers => { 'Content-Type' => 'application/json' },
                             :authorization => @client.authorization.dup)
    #puts result.data.updated
  end

  # Updates event
  def delete_event(event)
    puts "DELETE " + event.summary

    # Update event information
    result = @client.execute(:api_method => @calendar.events.delete,
                             :parameters => {
                              'calendarId' => @calendar_id,
                              'eventId' => event.id
                             },
                             )
  end

  # Convert Time object to '2011-06-03T10:25:00.000-07:00'
  def time_to_google(time)
    s = time.strftime("%Y-%m-%dT%H:%M:%S.000%z")
    s[0..25] + ':' + s[26..27]
  end

  # Convert Google dateTime '2011-06-03T10:25:00.000-07:00' to Time
  # object
  def google_to_time(dt)
    d = elems[0].content.split('.')
    t = elems[2].content.split(':')
    Time.new('20' + d[2], d[1], d[0], t[0], t[1])
  end

end
