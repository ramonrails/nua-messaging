class User < ApplicationRecord

  has_one :inbox # FIXME: `dependent`?
  has_one :outbox # FIXME: `dependent`?
  has_many :payments # FIXME: `dependent`?
  # FIXME: no `through`?
  # INFO: assuming: inbox `messages` (default behaviour?).
  has_many :messages, through: :inbox

  # FIXME: this should ieally be plural by convention
  #   why make it tough for other developers to understand?
  #   code maintainability is at every step. right?
  scope :patients, -> { where(is_patient: true) }
  scope :admins, -> { where(is_admin: true) }
  scope :doctors, -> { where(is_doctor: true) }

  # INFO: class << self is recommended
  # FIXME: why not `take` instead of `first`? no need for scalability & performance?
  #        `take`, `first` applies default sort order by primary key, but of no use here
  # INFO: using `alias`. not touching your code because I don't want to trigger code refactor hell
  # FIXME: performance concerns in DB query every time
  #
  # 1. You can assume there will only be one doctor in the DB.
  # 2. You don't need to worry about sessions or security. You can call User.current to return the only patient in the system.
  # 
  # class methods --
  class << self
    def current
      User.patients.take
    end
    alias patient current

    def default_admin
      User.admins.take
    end
    alias admin default_admin

    def default_doctor
      User.doctors.take
    end
    alias doctor default_doctor

  end
  # -- class methods

  def full_name
    # FIXME: [first_name, last_name].compact.join(' ') for better user experience
    "#{first_name} #{last_name}"
  end
end