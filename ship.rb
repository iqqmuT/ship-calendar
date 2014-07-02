#!/usr/bin/ruby

class Ship

  attr_accessor :updated,
    :vessel,
    :nationality,
    :from,
    :to,
    :eta,
    :berth,
    :ets

  def to_s
    "#{@vessel} #{@nationality}"
  end

  def summary
    "#{@vessel} #{@nationality}"
  end

end
