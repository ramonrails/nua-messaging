class MessagesController < ApplicationController

  def show
    @message = Message.find(params[:id])
    @message&.mark_as_read
  end

  def new
    # FIXME: pass the original_message_id along (because virtual attribute)
    @message = Message.new(original_message_id: params[:original_message_id])
  end

  def create
    @message = Message.new(message_params)
    @message.attempt_payment

    if @message.save
      # FIXME: redirecting to the @message show page, marks it `read`
      redirect_to messages_path
    else
      render :new
    end
  end
  
  private

  def message_params
    params.require(:message).permit(:body, :original_message_id, :outbox_id, :inbox_id, :payment_ref)
  end
end
