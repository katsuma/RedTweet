class StatusController < ApplicationController
  MAX_GLOBAL_POST = 1000
  before_filter :require_login, :only => [:post]

  def post
    return redirect_to :action => :public_timeline unless request.post?

    post_id = @redis.incr("global:nextPostId")
    user_id = @login_user[:id]
    status = "#{Time.now}|#{post_id}|#{user_id}|#{params[:status]}"
    @redis.set("post:#{post_id}", status)

    # self
    @redis.lpush("uid:#{user_id}:posts", status)    

    # home
    @redis.lpush("uid:#{user_id}:home", status)    

    # push status to followers
    followers_ids = @redis.zrange("uid:#{user_id}:followers", 0, -1)
    followers_ids.each do |id|
      @redis.lpush("uid:#{id}:home", status)
    end
    
    # push status to public timeline
    @redis.lpush("global:timeline", status)
    @redis.ltrim("global:timeline", 0, MAX_GLOBAL_POST)

    rt = params[:rt]
    if rt
      redirect_to rt
    else
      redirect_to :controller => :user, :action => :home
    end
  end

  def show(id = 0)
    redirect_to :controller => :user, :action => :home unless id > 0
    @status = status_data(id)
  end

  def public_timeline
    page = params[:page] || "1"
    per_page = 20
    start_index = per_page * (page.to_i - 1)

    @statuses = []
    status_post_ids = @redis.lrange("global:timeline", start_index, start_index + per_page)
    status_post_ids.each do |id|
      @statuses << status_data(id)
    end

    load_login_user if is_login

  end
end
