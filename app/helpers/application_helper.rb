include UserFunctions
module ApplicationHelper
  def login?
    is_login
  end

  def following?(user_id)
    is_following user_id
  end
end
