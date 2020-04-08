class Provider
  def debit_card(user = nil)
    # randomly pass or fail payment gateway
    ['4111-1111-1111-1111', nil][rand(0..1)] # test VISA card
  end
end
