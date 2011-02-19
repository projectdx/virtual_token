class TokenRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :token, :inverse_of => :requests
  acts_as_list :scope => :token

  validates_presence_of :user
  validates_presence_of :token
  validates_presence_of :purpose

  delegate :name, :to => :user, :prefix => true
end
