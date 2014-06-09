module Spree
  class Gateway::PayUMoney < Gateway
    require "open-uri"
    require "net/https"

    # Production Preferences
    preference :post_url, :string, :default => "https://secure.payu.in/_payment"

    preference :key, :string, :default => "4834548"
    preference :salt, :string

    # Test Preferences
    preference :test_post_url, :string, :default => "https://test.payu.in/_payment"

    preference :test_key, :string, :default => "JBZaLc"
    preference :test_salt, :string, :default => "GQs7yium"
    
    preference :test_card_name, :string, :default => 'Test Bank Visa Card'
    preference :test_card_number, :string, :default => '5123456789012346'
    preference :test_cvv, :string, :default => '123'
    preference :test_expiry, :string, :default => 'May 2017'

    mattr_accessor :test_post_url
    mattr_accessor :post_url
    mattr_accessor :test_key

    def provider_class
      ActiveMerchant::Billing::Integrations::PayuIn
    end

    def auto_capture?
      true
    end

    def purchase(money, credit_card, options = {})
      # redirect1 "https://test.payu.in/_payment"

      # provider = credit_card_provider(credit_card, options)
      # provider.purchase(money, credit_card, options)

      url = URI.parse(:test_post_url)
      req = Net::HTTP::Post.new(url.path)
      req.form_data = {}
      con = Net::HTTP.new(url.host, url.port)
      con.use_ssl = true
      con.start {|http| http.request(req)}
    end

    def authorize(money, credit_card, options = {})
      redirect "https://test.payu.in/_payment"
    #   provider = credit_card_provider(credit_card, options)
    #   provider.authorize(money, credit_card, options)
    end

    def capture(money, authorization, options = {})
      # redirect2 "https://test.payu.in/_payment"
    #   provider = credit_card_provider(auth_credit_card(authorization), options)
    #   provider.capture(money, authorization, options)
    end

    # def refund(money, authorization, options = {})
    #   provider = credit_card_provider(auth_credit_card(authorization), options)
    #   provider.refund(money, authorization, options)
    # end

    # def credit(money, authorization, options = {})
    #   refund(money, authorization, options)
    # end

    # def void(authorization, options = {})
    #   provider = credit_card_provider(auth_credit_card(authorization), options)
    #   provider.void(authorization, options)
    # end

    private

    def options_for_card(credit_card, options)
      options[:login] = login_for_card(credit_card)
      options = options().merge( options )
    end

    def auth_credit_card(authorization)
      Spree::Payment.find_by_response_code(authorization).source
    end

    def credit_card_provider(credit_card, options = {})
      gateway_options = options_for_card(credit_card, options)
      gateway_options.delete :login if gateway_options.has_key?(:login) and gateway_options[:login].nil?
      gateway_options[:currency] = self.preferred_currency
      gateway_options[:inst_id] = self.preferred_installation_id
      ActiveMerchant::Billing::Base.gateway_mode = gateway_options[:server].to_sym
      @provider = provider_class.new(gateway_options)
    end

    def login_for_card(card)
      case card.brand
        when 'american_express'
          choose_login preferred_american_express_login
        when 'maestro'
          choose_login preferred_maestro_login
        when 'master'
          choose_login preferred_mastercard_login
        when 'visa'
          choose_login preferred_visa_login
        else
          preferred_login
      end
    end

    def choose_login(login)
      return login ? login : preferred_login
    end
  end
end
