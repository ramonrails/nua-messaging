class Message < ApplicationRecord
  # 3. Your design should assume that a doctor will have **hundreds of thousands of messages** in their inbox.
  #
  # FIXME: ideally, link the original message to this one, you will also get a message thread
  # FIXME: linking every `thread` message to a common `root` message will also enable
  #   - entire thread in single SQL query
  #   - order by created_at to get the thread order for user experience
  #
  # INFO: assuming I am not authorised to change the DB structure. right?
  #   so, just using virtual attribute to get the job done
  attr_accessor :original_message_id, :payment_ref, :payment_confirmation

  belongs_to :inbox
  belongs_to :outbox

  before_validation :assign_the_boxes
  before_save :manage_payment
  after_save :update_inbox_with_new_message_received

  # Doctors have requested the ability to quickly see how many unread messages they have in their inbox.
  # usage: User.<whichever>.inbox.unread => unread messages
  scope :unread, -> { where(read: false) }

  def paid?
    payment_confirmation.present?
  end

  def attempt_payment
    # do not attempt if we did not receive user authorization
    return if payment_ref.blank?
    # fail or pass?
    self.payment_confirmation = PaymentProviderFactory.provider.debit_card(User.patient)
    # gracefully update the message, if failed (or some other action)
    self.body = '(Pay) ' + body
  end

  # called from the controller when this message is shown
  def mark_as_read
    # reduce unread count when user opens this message
    unless read?
      self.update_attribute(:read, true) # mark as read
      self.inbox.decrement!(:unread_messages_count) # default decrement by 1
    end
  end

  def received_this_week?
    # FIXME: assuming
    #   neither time zones are in scope here,
    #   nor specific time of the day (00hrs to 23:59hrs)
    #   a week can be calculated from any moment in time (any second)
    created_at >= 1.week.ago
  end

  def original_message
    # INFO: not thinking about memoization here. performance is out of scope. right?
    original_message_id.presence && Message.find(original_message_id)
  end

  private

    def manage_payment
      Payment.create user: User.patient if payment_confirmation
    end
    
    # new message received, set marker
    def update_inbox_with_new_message_received
      # increament if this message was just created
      # do not touch otherwise
      self.inbox.increment!(:unread_messages_count) if id_changed? # or, created_at == updated_at
    end

  # `&` will save you a few exceptions
    def assign_the_boxes
      # INFO: sender is always current user
      self.outbox ||= User.patient&.outbox

      # INFO: use `&`, to avoid exception cases
      # original_message will be blank for payment message, so it will automatically go to admin
      if original_message&.received_this_week?
        # However, a message should only be sent to a doctor if the original message was created in the past week.
        self.inbox ||= User.doctor&.inbox
      else
        # If the original message was created more than a week ago then the message should be routed to an Admin.
        self.inbox ||= User.admin&.inbox
      end
    end
end