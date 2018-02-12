# frozen_string_literal: true

require 'uri'
require_relative 'line_adapter'
require_relative 'db_adapter'

module MessageHandle
  include LineAdapter
  include DbAdapter

  def message_handle(event)
    case event
    when Line::Bot::Event::Message
      case event.type.to_s
      when Line::Bot::Event::MessageType::Text
        on_text_message event
      when Line::Bot::Event::MessageType::Image
        on_image_message(event)
      when Line::Bot::Event::MessageType::Video
        on_video_message(event)
      when 'File'
        on_file_message(event)
      else
        STDERR.puts "No match event type: -#{event.type.inspect}-"
      end
    end
  end

  def on_file_message(event)
    filename = event.message['fileName']
    reply_token, message_id, sender, room_id = event_param(event)
    temp_file = save_content(message_id)
    sent_to = get_emails(room_id)
    send_attached(
      sent_to,
      "From Line chat #{get_room_name(room_id)}",
      "#{sender['displayName']} has sent",
      temp_file,
      event.message['fileName']
    )
    reply_text(reply_token, "#{filename} is sent to #{sent_to}").body
  end

  def on_image_message(event)
    reply_token, message_id, sender, room_id = event_param(event)
    filename = event.message['id'] + '.jpg'
    temp_file = save_content(message_id)
    send_attached(
      get_emails(room_id),
      "From Line chat #{get_room_name(room_id)}",
      "#{sender['displayName']} has sent",
      temp_file,
      filename
    )
    reply_text(reply_token, "Image is sent to #{get_emails(room_id)}").body
  end

  def on_video_message(event)
    reply_token, message_id, sender, room_id = event_param(event)
    filename = message_id + '.mp4'
    temp_file = save_content(message_id)
    send_attached(
      get_emails(room_id),
      "From Line chat #{get_room_name(room_id)}",
      "#{sender['displayName']} has sent",
      temp_file,
      filename
    )
    reply_text(reply_token, "Video is sent to #{get_emails(room_id)}").body
  end

  def save_content(message_id)
    response = client.get_message_content(message_id)
    tf = Tempfile.open('content')
    tf.write(response.body)
    tf
  end

  def event_param(event)
    reply_token = event['replyToken']
    message_id = event.message['id']
    sender = get_profile(event['source']['userId'])
    room_id = room_id(event)
    [reply_token, message_id, sender, room_id]
  end

  def room_id(event)
    event['source']['roomId'] || event['source']['groupId'] || event['source']['userId']
  end

  def on_text_message(event)
    got_message = event.message['text'].strip
    reply_token = event['replyToken']
    user_id = event['source']['userId']
    room_id = room_id(event)

    if got_message.start_with?('_bot')
      on_nice_message(got_message, reply_token, user_id, room_id)
    end
  end

  def on_nice_message(message, reply_token, user_id, room_id)
    case message
    when /add_email/i
      address = message.partition('=')[2].strip
      if URI::MailTo::EMAIL_REGEXP.match?(address)
        add_email room_id, address
        p reply_text(reply_token, "I will add #{address}").body
      else 
        p reply_text(reply_token, "Invalid e-mail #{address}").body
      end
    when /room_name/i
      name = message.partition('=')[2].strip
      set_room_name room_id, name
      p reply_text(reply_token, "Set room to #{name}").body
    end
  end
end
