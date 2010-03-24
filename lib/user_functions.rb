module UserFunctions
  def user_data(user_id = 0)
    return nil unless user_id > 0

    user_name = @redis.get("uid:#{user_id}:username")
    following = @redis.zcard("uid:#{user_id}:following")
    followers = @redis.zcard("uid:#{user_id}:followers")
    updates = @redis.llen("uid:#{user_id}:posts")

    return { 
      :id => user_id, 
      :name => user_name,
      :following => following.to_i,
      :followers => followers.to_i,
      :updates => updates.to_i
    }    
  end

  def is_login
    session_auth = cookies[:auth]
    return false if @redis.get("uid:#{session_auth}").nil?
    true
  end

  def is_following(user_id = 0)
    return false unless user_id > 0 && is_login
    return false if @redis.zscore("uid:#{@login_user[:id]}:following", user_id).nil?
    true
  end
end
