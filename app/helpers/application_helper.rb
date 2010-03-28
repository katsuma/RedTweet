include UserFunctions
module ApplicationHelper
  def login?
    is_login
  end

  def following?(user_id)
    is_following user_id
  end

  def time_format(str)
    return "" unless str
    time_ago_in_words(Time.parse str)
  end
end
