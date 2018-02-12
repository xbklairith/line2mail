require 'mongoid'

# Show
class Room
  include Mongoid::Document
  field :room_id
  field :room_name
  field :emails, type: Array, default: []
  field :dont_report, type: Boolean, default: false
  field :sent_to, type: Array, default: []
  field :usual_workers, type: Array, default: []
end

module DbAdapter
  def add_email room_id, address
    room = Room.where(
      room_id: room_id
    ).first_or_create
    room[:emails] |= [address]
    room.save
  end

  def set_room_name room_id, name
    room = Room.where(
      room_id: room_id
    ).first_or_create
    room[:room_name] = name
    room.save
  end
  def get_emails room_id
    room = Room.where(
      room_id: room_id
    ).first_or_create
    room[:emails]
  end

  def get_room_name room_id
    room = Room.where(
      room_id: room_id
    ).first_or_create
    room[:room_name]
  end

end