class TokenRequestsController < ApplicationController
  skip_before_filter :authenticate_user!, :only => :index

  def index
    redirect_to token_path(params[:token_id])
  end

  def create
    token_params = (params[:token_request] || {}).merge(:user => current_user)
    @token = Token.find_by_slug!(params[:token_id])
    @token.create_request!(token_params)
    redirect_to @token
  rescue ActiveRecord::RecordInvalid => e
    @new_token_request = e.record
    render 'tokens/show'
  end

  def destroy
    TokenRequest.destroy(params[:id])
    redirect_to token_path(params[:token_id])
  end
end
