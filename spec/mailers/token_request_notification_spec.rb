require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe TokenRequestNotification do
  describe "claim_granted" do
    let(:mail) do
      token = mock_model('Token', :name => 'Yodeling Pickle', :to_param => 'yodeling-pickle')
      user = mock_model('User', :name => 'John Doe', :email => 'to@example.org')
      req = TokenRequest.new(:token => token, :user => user,
                             :purpose => 'Make Norwegian pickle-lovers hungry.')
      TokenRequestNotification.claim_granted(req)
    end

    it "renders the headers" do
      expect(mail.subject).to eq("It's your turn with the Yodeling Pickle token")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["no-reply@virtual-token.heroku.com"])
    end

    it "renders the body" do
      mail_body_fixture_path = File.join(Rails.root, 'spec', 'fixtures',
                                         'token_request_notification',
                                         'claim_granted')
      expect(mail.body.encoded).to match(File.read(mail_body_fixture_path))
    end
  end
end
