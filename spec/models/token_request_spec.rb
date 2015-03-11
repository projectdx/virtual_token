require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe TokenRequest do
  let(:user) { mock_model('User').as_null_object }
  let(:token) { mock_model('Token').as_null_object }
  let(:request) { TokenRequest.new(:user => user, :token => token) }

  describe '#grant_claim' do
    context 'the request has already been granted the claim' do
      before(:each) do
        allow(request).to receive_messages(:claim_granted? => true)
      end

      it 'does not update the #claim_granted_at attribute is is is already set' do
        time = 3.hours.ago
        request.claim_granted_at = time
        request.grant_claim
        expect(request.claim_granted_at).to eq(time)
      end

      it 'does not send the notification message' do
        expect(TokenRequestNotification).not_to receive(:claim_granted)
        request.grant_claim
      end
    end

    context 'the request has not already been granted the claim' do
      before(:each) do
        allow(request).to receive_messages(:claim_granted? => false)
      end

      it 'updates the #claim_granted_at attribute if it is not already set' do
        Timecop.freeze
        time = Time.now
        request.grant_claim
        Timecop.return
        expect(request.claim_granted_at).to eq(time)
      end

      it 'sends the notification message' do
        mail = double('TokenRequestNotification')
        expect(TokenRequestNotification).to receive(:claim_granted) \
          .with(request).and_return(mail)
        expect(mail).to receive(:deliver_now)
        request.grant_claim
      end
    end
  end

  describe 'revoke_claim' do
    it 'should set claim_granted_at to nil' do
      request.claim_granted_at = Time.now
      request.revoke_claim
      expect(request.claim_granted_at).to be_nil
    end
  end

  describe '#move' do
    before(:each) do
      @user = User.create!(:name => 'froo', :email => 'froo@example.com', :password => '12345678')
      @token = Token.create!(:name => 'Boozles')
      @current_request = @token.requests.create!(:purpose => 'for boozling', :user => @user)
      @tr1 = @token.requests.create!(:purpose => 'for boozling some more', :user => @user)
      @tr2 = @token.requests.create!(:purpose => 'for boozling a lot more', :user => @user)
      @tr3 = @token.requests.create!(:purpose => 'for boozling all the way', :user => @user)
    end

    context 'when moving up' do
      it 'should swap positions with the token above it in the queue' do
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        @tr2.move('up')
        expect(@token.queue).to eq([@tr2, @tr1, @tr3])
      end

      it 'should do nothing if at the top of the queue already' do
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        @tr1.move('up')
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        expect(@token.current_request).to eq(@current_request)
      end
    end

    context 'when moving down' do
      it 'should swap positions with the token below it in the queue' do
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        @tr1.move('down')
        expect(@token.queue).to eq([@tr2, @tr1, @tr3])
      end

      it 'should do nothing if at the bottom of the queue already' do
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        @tr3.move('down')
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
      end
    end

    context 'when moving to top' do
      it 'should move to the top of the queue' do
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        @tr3.move('top')
        expect(@token.queue).to eq([@tr3, @tr1, @tr2])
      end

      it 'should do nothing if at the top of the queue already' do
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        @tr1.move('top')
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        expect(@token.current_request).to eq(@current_request)
      end
    end

    context 'when moving to bottom' do
      it 'should move to the bottom of the queue' do
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        @tr1.move('bottom')
        expect(@token.queue).to eq([@tr2, @tr3, @tr1])
      end

      it 'should do nothing if at the bottom of the queue already' do
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
        @tr3.move('bottom')
        expect(@token.queue).to eq([@tr1, @tr2, @tr3])
      end
    end

    context 'when claiming' do
      it 'becomes the current_request' do
        @tr2.move('claim')
        expect(@token.current_request(true)).to eq(@tr2)
      end

      it 'pushes the previously-current request down to the top of the queue' do
        @tr2.move('claim')
        expect(@token.queue).to eq([@current_request, @tr1, @tr3])
      end
    end
  end
end
