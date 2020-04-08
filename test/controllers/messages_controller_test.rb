require 'test_helper'

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    # FIXME: make sure users exist
    patient = User.current || User.create(is_patient: true)
    doctor = User.doctor || User.create(is_doctor: true)
    admin = User.admin || User.create(is_admin: true)
    # ensure required boxes
    patient.outbox || patient.create_outbox
    doctor.inbox || doctor.create_inbox
    admin.inbox || admin.create_inbox

    @message = Message.create outbox: patient.outbox, inbox: doctor.inbox
  end

  test "should get index" do
    get messages_url
    assert_response :success
  end

  test "should get new" do
    get new_message_url
    assert_response :success
  end

  test "should create message" do
    assert_difference('Message.count') do
      post messages_url, params: { message: @message.attributes }
    end

    # redirecting to message show page causes it to be `read`, so send to the list
    assert_redirected_to messages_url
  end

  # 2. That the number of unread messages is incremented when a doctor is sent a message
  test "should increment unread count for doctor" do
    message = Message.new(outbox: User.patient.outbox, inbox: User.doctor.inbox)

    assert_difference('User.doctor.inbox.unread_messages_count') do
      post messages_url, params: { message: message.attributes }
    end
    # redirecting to message show page causes it to be `read`, so send to the list
    assert_redirected_to messages_url
  end

  # 2. That the number of unread messages is incremented when a doctor is sent a message
  test "should increment unread count for doctor, with related original message" do
    message = Message.create # patient -> admin (as per logic)

    assert_difference('User.doctor.inbox.unread_messages_count') do
      # within a week, gets assigned to doctor
      post messages_url, params: { message: { original_message_id: message.id } }
    end
    # redirecting to message show page causes it to be `read`, so send to the list
    assert_redirected_to messages_url
  end

  # A lost script message is sent to the admin and the Payment API is called and Payment Record is created
  test "lost script message is sent to the admin" do
    message = Message.new(payment_ref: "abcdef123")

    assert_difference('User.patient.payments.count', Message.last.paid? ? 1 : 0) do
      post messages_url, params: { message: message.attributes }
    end
    # redirecting to message show page causes it to be `read`, so send to the list
    assert_redirected_to messages_url
  end

  test "should show message" do
    get message_url(@message)
    assert_response :success
  end

  def teardown
    User.delete_all
    Inbox.delete_all
    Outbox.delete_all
    Message.delete_all
  end
end
