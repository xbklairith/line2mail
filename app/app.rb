# frozen_string_literal: true

require 'logger'
require 'sinatra'
require 'config'
require 'redis'
require 'line/bot'
require 'pry'
require 'time'
require 'rufus-scheduler'
require 'open-uri'

class LineBotEngine < Sinatra::Application
  get '/' do
    'Line bot webhook'
  end

  get '/trig' do
    'ok'
  end
end
