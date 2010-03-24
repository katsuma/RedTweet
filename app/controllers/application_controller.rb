# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include StatusFunctions
  include UserFunctions
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  before_filter :init_redis

  def init_redis
    @redis = Redis.new
  end


  def load_login_user
    session_auth = cookies[:auth]
    @login_user = user_data @redis.get("uid:#{session_auth}").to_i
  end

  def require_login
    session_auth = cookies[:auth]
    return redirect_to :controller => :user, :action => :login if @redis.get("uid:#{session_auth}").nil?

    load_login_user
  end
end
