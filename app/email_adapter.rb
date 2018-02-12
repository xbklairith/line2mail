# frozen_string_literal: true

# Mixin email tools
module MailAdapter
  def send_attached(sent_to, subject, message, file, filename=nil)
    mail = Mail.new do
      from    'Line2Mail Bot'
      to      sent_to
      subject subject
      body    message
      add_file filename: filename || File.basename(file), content: File.read(file)
    end
    mail.deliver!
  end
end
