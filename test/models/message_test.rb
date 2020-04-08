require 'test_helper'
 
class MessageTest < ActiveSupport::TestCase
  # FIXME: too much happening in each test actually
  #   ideally, only single assert per test case
  #   split the test cases into smaller ones
  #   but it also increases the time required for the test run
  #   choose wisely

  # test environment setup
  def setup
    # FIXME: make sure users exist
    patient = User.current || User.create(is_patient: true)
    doctor = User.doctor || User.create(is_doctor: true)
    admin = User.admin || User.create(is_admin: true)
    # ensure required boxes
    patient.outbox || patient.create_outbox
    doctor.inbox || doctor.create_inbox
    admin.inbox || admin.create_inbox
  end

  test 'has an unread status after creation' do
    # when a message is created
    message = Message.create
    # verify persisted, or the test result might fool you. try it.
    assert_predicate message, :persisted?
    # then it is unread
    assert_not message.read?
    # or use predicate
    assert_not_predicate message, :read?
  end

  # within this week
  test 'is sent to the correct inbox and outbox after creation' do
    # when an original message is created
    original_message = Message.create(inbox: User.patient.inbox, outbox: User.doctor.outbox)
    # verify the original message has persisted
    assert_predicate original_message, :persisted?
    # and a message created in its's response
    message = Message.create(original_message_id: original_message.id)
    # verify persisted, or the test result might fool you. try it.
    assert_predicate message, :persisted?

    # now we check the actual stuff

    # message sent to the doctor (because, within this week)
    assert_equal message.inbox, User.doctor.inbox
    # outbox is of the patient. you're replying to the doctor.
    assert_equal message.outbox, User.patient.outbox
  end

  test 'we can have a test -- when original message over a week old, send reply to admin' do
    # INFO: we need time travel. Timecop gem?
    # was this in the scope of assessment?
  end

  test 'number of unread messages is incremented when a doctor is sent a message' do
    message = Message.new(inbox: User.doctor.inbox, outbox: User.patient.outbox)
    assert_difference('User.doctor.inbox.unread_messages_count') do
      Message.create(message.attributes)
    end
  end

  test 'number of unread messages is incremented when a doctor is sent a message with an original message' do
    original = Message.create # patient -> admin (as per logic)
    assert_difference('User.doctor.inbox.unread_messages_count') do
      # within a week, gets assigned to doctor
      Message.create(original_message_id: original.id)
    end
  end

  # cleanup after yourself, or get ready to get fooled by unexpected test results
  # don't blame it on the computer, language or test framework. It's you. :)
  def teardown
    User.delete_all
    Inbox.delete_all
    Outbox.delete_all
    Message.delete_all
  end

end