class Eveuser < Ohm::Model
  attribute :name
  attribute :enabled
  unique :name
  index :name
  collection :evekeypairs, :Evekeypair
end

class Evekeypair < Ohm::Model
  attribute :keyid
  attribute :vcode
  index :keyid
  index :vcode
  reference :eveuser, :Eveuser
end
