# frozen_string_literal: true

require 'logger'
require 'sinatra'
require 'config'
require 'redis'
require 'line/bot'
require 'pry'
require 'time'
require 'rufus-scheduler'
require 'mail'
require 'open-uri'
require 'mongoid'

require_relative 'line_adapter'
require_relative 'email_adapter'
require_relative 'message_handle'

# LineBotEngine controller
class LineBotEngine < Sinatra::Application
  include LineAdapter
  include MailAdapter
  include MessageHandle

  set :root, File.join(File.dirname(__FILE__), '..')
  register Config

  Mail.defaults do
    options = {
      address:              Settings.mail.smtp_server,
      port:                 Settings.mail.port,
      user_name:            Settings.mail.username,
      password:             Settings.mail.password,
      authentication:       Settings.mail.auth_mode,
      enable_starttls_auto: true
    }
    delivery_method :smtp, options
  end

  Mongoid.load!('config/mongoid.yml', :development)
  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = Settings.line.channel_secret
      config.channel_token  = Settings.line.channel_token
    end
  end

  get '/' do
    'Line bot webhook'
  end

  get '/irb' do
    # send_attached 'xbird007@gmail.com', 'From line chat', 'user has send file', '/Users/xb/Desktop/stes.png'
    puts get_profile 'U9effa0547d8fe2e702f923c9f5620be0'
    "ok"
  end

  get '/trig' do
    'ok'
  end

  get '/callback' do
    p request
  end

  get '/content/:message_id' do |message_id|
    tmpfile = save_content message_id
    send_file tmpfile
  end

  get '/profile/:user_id' do |user_id|
    get_profile(user_id).to_s
  end

  post '/callback' do
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end
    events = client.parse_events_from(body)
    events.each do |event|
      STDERR.puts event.inspect
      message_handle event
      # p event
    end
    'OK'
  end
end
