class PaymentProviderFactory
  # shortcut to achieve the test requirements
  class << self
    def provider
      Provider.new
    end
  end
end