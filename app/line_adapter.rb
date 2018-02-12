# frozen_string_literal: true

# Line
module LineAdapter
  def reply_img(reply_token, ori_img_url, pre_img_url)
    img_msg = make_img ori_img_url, pre_img_url
    p img_msg
    response = client.reply_message(reply_token, img_msg)
    response
  end

  def reply_text(reply_token, message)
    text_msg = make_text message
    response = client.reply_message(reply_token, text_msg)
    response
  end

  def push_text(send_to, message)
    text_msg = make_text message
    response = client.push_message(send_to, text_msg)
    if response.is_a? Net::HTTPSuccess
      p 'HTTPSuccess'
      'OK'
    else
      p 'HTTPError'
      response.body
    end
  end

  def send_card(line_user, img_url, title, text, label)
    message = make_card img_url, title, text, label
    response = client.push_message(line_user, message)
    puts 'send_card'
    puts JSON.pretty_generate message
    if response.is_a? Net::HTTPSuccess
      p 'HTTPSuccess'
      'OK'
    else
      p 'HTTPError'
      response.body
    end
  end

  def make_card(img_url, title, text, label)
    {
      "type":     'template',
      "altText":  'this is a buttons template',
      "template": {
        "type":   'buttons',
        "thumbnailImageUrl": img_url,
        "title": title,
        "text": text,
        "actions": [
          {
            "type": 'postback',
            "label": label,
            "data": 'action=ok&itemid=123'
          }
        ]
      }
    }
  end

  def make_text(message)
    {
      "type": 'text',
      "text": message
    }
  end

  def make_img(orignal_url, preview_url)
    {
      "type": 'image',
      "originalContentUrl": orignal_url,
      "previewImageUrl": preview_url
    }
  end

  def save_content(message_id)
    response = client.get_message_content(message_id)
    case response
    when Net::HTTPSuccess then
      tf = Tempfile.open('content')
      tf.write(response.body)
      return tf
    else
      p "#{response.code} #{response.body}"
    end
  end

  def get_profile(user_id)
    # return {displayName, pictureUrl statusMessage}

    response = client.get_profile(user_id)
    case response
    when Net::HTTPSuccess then
      contact = JSON.parse(response.body)
      return contact
    else
      STDERR.puts "Get profile errors#{response.code} #{response.body}"
      blank_result = {
        "displayName":   '',
        "pictureUrl":    '',
        "statusMessage": ''
      }

      return blank_result
    end
  end
end
