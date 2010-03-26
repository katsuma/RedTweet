class UserController < ApplicationController
  require 'digest/sha1' 
  include StatusFunctions

  before_filter :require_login, :except => [:create, :login]
  MERGE_MAX_POSTS = 100

  def create
    return unless request.post?
    @message = "require_input" and return unless params[:username] and params[:password]
    
    username = params[:username]
    password = params[:password]

    @message = "require_input" and return unless username.match(/^[0-9a-zA-Z]+$/) and password.match(/^[!-~]+$/)
    @message = "registered_username" and return unless @redis.get("#{username}:antirez:uid").nil?
    
    user_id = @redis.incr('global:nextUserId')

    @redis.set("uid:#{user_id}:username", username)
    @redis.set("uid:#{user_id}:password", password_digest(password))
    @redis.set("#{username}:antirez:uid", user_id)

    create_session(user_id)
    return redirect_to :action => :home
  end
  
  def login
    username = params[:username]
    password = params[:password]

    return unless request.post? && username && password

    user_id = @redis.get("#{username}:antirez:uid")

    @message = "incorrect_password" and return unless @redis.get("uid:#{user_id}:password") == password_digest(password)
 
    create_session(user_id)
    return redirect_to :action => :home
  end

  def create_session(user_id)
    session = session_digest
    @redis.set("uid:#{user_id}:auth", session)
    @redis.set("uid:#{session}", user_id)
    cookies[:auth] = { :value => session, :expires => 30.days.from_now, :path => "/" }
  end
  private :create_session

  def logout
    cookies[:auth] = { :value => nil, :expires => Time.local(1999, 1, 1)}
    return redirect_to :controller => :status, :action => :public_timeline
  end

  def home
    user_timeline @login_user[:id]
  end

  def show
    id = (params[:id] || "0").to_i
    @user = user_data id
    user_timeline id, :posts
  end

  def user_timeline(id, type = :home)
    return redirect_to :controller => :status, :action => :public_timeline unless id > 0
    
    page = params[:page] || "1"
    per_page = 20
    start_index = per_page * (page.to_i - 1)
    @statuses = []
    
    status_ids = @redis.lrange("uid:#{id}:#{type.to_s}", start_index, start_index + per_page)
    status_ids.each do |id|
      @statuses << status_data(id)
    end
  end
  private :user_timeline

  def following
    id = (params[:id] || "0").to_i
    page = params[:page] || "1"
    per_page = 20
    start_index = per_page * (page.to_i - 1)
    following_ids = @redis.zrange("uid:#{id}:following", start_index, start_index + per_page)

    @following = []
    following_ids.each do |id|
      @following << { :id => id, :name => @redis.get("uid:#{id}:username") }
    end    
    @user = { :id => id, :name => @redis.get("uid:#{id}:username") }
  end

  def followers(id = 0)
    page = params[:page] || "1"
    per_page = 20
    start_index = per_page * (page.to_i - 1)
    id = @login_user[:id] if id == 0
    followers_ids = @redis.zrange("uid:#{id}:followers", start_index, start_index + per_page)

    @followers = []
    followers_ids.each do |id|
      @followers << { :id => id, :name => @redis.get("uid:#{id}:username") }
    end
  end

  def follow
    id = (params[:id] || "0").to_i
    return redirect_to :action => :home unless id > 0
    score = Time.now.to_i
    @redis.zadd("uid:#{id}:followers", score, @login_user[:id])
    @redis.zadd("uid:#{@login_user[:id]}:following", score, id)
    merge_timeline id
    return redirect_to :controller => :user, :action => :show, :id => id, :follow => 1
  end

  def merge_timeline(user_id)
    my_id = @login_user[:id]
    return if @redis.type?("uid:#{user_id}:posts") == "none"

    user_statuses = @redis.lrange("uid:#{user_id}:posts", 0, 100)
    user_statuses.each do |status|
      @redis.lpush("uid:#{my_id}:home", status)
    end
    @redis.sort("uid:#{my_id}:home", :order => "desc alpha", :store => "uid:#{my_id}:home:new")
    @redis.delete("uid:#{my_id}:home")
    @redis.rename("uid:#{my_id}:home:new", "uid:#{my_id}:home")
  end
  private :merge_timeline

  def remove
    id = (params[:id] || "0").to_i
    return redirect_to :action => :home unless id > 0

    @redis.zrem("uid:#{id}:followers", @login_user[:id])
    @redis.zrem("uid:#{@login_user[:id]}:following", id)
    return redirect_to :controller => :user, :action => :show, :id => id, :remove => 1
  end

  def password_digest(phrase)
    pref_password = "redtweet-"
    Digest::SHA1.hexdigest("#{pref_password}-#{phrase}")
  end
  private :password_digest

  def session_digest
    Digest::SHA1.hexdigest("#{Time.now.to_s}-#{rand.to_s}")    
  end
  private :session_digest
end
