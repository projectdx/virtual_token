require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe Token do
  describe '.generate_slug' do
    it 'returns the lowercase, dasherized version of the token name' do
      expect(Token.generate_slug('@The #sluG   loO0ks#!$% like THIS!')) \
        .to eq('the-slug-loo0ks-like-this')
    end
  end

  describe '.create' do
    it 'sets the slug based on the token name' do
      t = Token.create!(:name => 'Foo Bar')
      expect(t.slug).to eq(Token.generate_slug('Foo Bar'))
    end
  end

  describe '#to_param' do
    it 'returns the token slug' do
      t = Token.create!(:name => 'Foo Bar')
      expect(t.to_param).to eq(t.slug)
    end
  end

  describe '#claimed?' do
    context 'there are no requests for the token' do
      it 'should return false' do
        t = Token.new
        expect(t.claimed?).to eq(false)
      end
    end

    context 'there are one or more requests for the token' do
      it 'should return true' do
        t = Token.new
        t.requests << mock_model('TokenRequest', :set_token_target => nil)
        expect(t.claimed?).to eq(true)
      end
    end
  end

  describe '#claimed_at' do
    it 'returns nill when there are no token requests' do
      token = Token.new
      expect(token.claimed_at).to be_nil
    end

    it 'returns TokenRequest#claim_granted_at from the current_request' do
      token = Token.new
      Timecop.travel(3.hours.ago)
      claim_time = Time.now
      token.requests << mock_model('TokenRequest', :claim_granted_at => claim_time, :set_token_target => nil)
      Timecop.return
      token.requests << mock_model('TokenRequest', :set_token_target => nil)
      expect(token.claimed_at).to eq(claim_time)
    end
  end

  describe '#claimed_by' do
    it 'returns nil when there are no token requests' do
      token = Token.new
      expect(token.claimed_by).to be_nil
    end

    it 'returns the user associated with the current_request' do
      token = Token.new
      request = mock_model('TokenRequest', :user => :bilbo)
      allow(token).to receive_messages(:current_request => request)
      expect(token.claimed_by).to eq(:bilbo)
    end
  end

  describe '#claim_purpose' do
    it 'returns nil when there are no token requests' do
      token = Token.new
      expect(token.claim_purpose).to be_nil
    end

    it 'returns the purpose associated with the first request' do
      token = Token.new
      token.requests << mock_model('TokenRequest', :purpose => 'Foo', :set_token_target => nil)
      token.requests << mock_model('TokenRequest', :purpose => 'Bar', :set_token_target => nil)
      expect(token.claim_purpose).to eq('Foo')
    end
  end

  describe '#current_request' do
    it 'returns #requests.first' do
      token = Token.new
      expect(token).to receive(:requests).with(false).and_return([:request_a, :request_b])
      expect(token.current_request).to be === :request_a
    end

    it 'reloads the requests association when `true` is passed' do
      token = Token.new
      expect(token).to receive(:requests).with(true).and_return([])
      token.current_request(true)
    end
  end

  describe '#queue' do
    it 'returns requests that have not been granted the claim' do
      t = Token.new
      requests_proxy = double('Token#requests')
      expect(requests_proxy).to receive(:where) \
        .with(:claim_granted_at => nil) \
        .and_return([:req_a, :req_b])
      allow(t).to receive_messages(:requests => requests_proxy)
      expect(t.queue).to eq([:req_a, :req_b])
    end
  end

  describe '#has_queue?' do
    context 'when there is no queue for this token' do
      it 'returns false' do
        t = Token.new
        allow(t).to receive_messages(:queue => [])
        expect(t.has_queue?).to eq(false)
      end
    end

    context 'when there is a queue for this token' do
      it 'returns true' do
        t = Token.new
        allow(t).to receive_messages(:queue => [mock_model('TokenRequest')])
        expect(t.has_queue?).to eq(true)
      end
    end
  end

  describe '#update_queue' do
    it 'reloads the requests association' do
      token = Token.new
      expect(token).to receive(:requests).with(true).and_return([])
      token.update_queue
    end

    it 'notifies the #current_request that it has claimed the token' do
      token = Token.new
      request = mock_model('TokenRequest', :set_token_target => nil)
      expect(request).to receive(:grant_claim)
      allow(token).to receive_messages(:current_request => request)
      token.update_queue
    end
  end
end
