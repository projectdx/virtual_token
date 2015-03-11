require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe TokensController do
  include Devise::TestHelpers

  describe 'routing' do
    it 'routes / to the new action' do
      expect({:get => '/'}).to route_to(:controller => 'tokens', :action => 'index')
    end

    it 'routes a POST to /tokens to the create action' do
      expect({:post => '/tokens'}).to route_to(:controller => 'tokens', :action => 'create')
      expect(tokens_path).to eq('/tokens')
    end

    it 'routes a GET to /tokens/:id to the show action' do
      expect({:get => '/tokens/foo'}).to route_to(:controller => 'tokens', :action => 'show', :id => 'foo')
      expect(token_path('foo')).to eq('/tokens/foo')
    end
  end

  context 'anonymous user' do
    describe '#new' do
      it 'requires an authenticated user' do
        get :new
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#create' do
      it 'requires an authenticated user' do
        post :create
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe '#show' do
      it 'requires an authenticated user' do
        get :create, :id => 'foo'
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'authenticated user' do
    before(:each) do
      s_user = double('User')
      request.env['warden'] = double('Warden', :authenticate => s_user, :authenticate! => s_user)
    end

    describe '#new' do
      it 'renders the new token template' do
        get :new
        expect(response).to render_template('tokens/new')
      end
    end

    describe '#create' do
      before(:each) do
        post :create, :token => {:name => 'A New Token'}
        expect(Token.count).to eq(1)
        @token = Token.last
      end

      it 'creates a new token with the specified name' do
        expect(@token.name).to eq('A New Token')
      end

      it 'redirects to the show action for the new token' do
        expect(response).to redirect_to(token_path(@token))
      end
    end

    describe '#show' do
      before(:each) do
        @token = mock_model('Token')
        allow(Token).to receive_messages(:find_by_slug! => @token)
      end

      it 'renders the token template' do
        get :show, :id => 'foo'
        expect(response).to render_template('tokens/show')
      end

      it 'assigns the specified token to the template' do
        expect(Token).to receive(:find_by_slug!).with('foo').and_return(@token)
        get :show, :id => 'foo'
        expect(assigns(:token)).to eq(@token)
      end

      it 'assigns a new token request to the template' do
        get :show, :id => 'foo'
        expect(assigns(:new_token_request)).to be_kind_of(TokenRequest)
        expect(assigns(:new_token_request)).to be_new_record
      end
    end
  end
end
