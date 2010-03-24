module StatusFunctions
  def status_data(status = nil)
    return nil unless status
    status_elements = status.split("|")
    return { 
      :id => id, 
      :user => { 
        :id => status_elements[0], 
        :name => @redis.get("uid:#{status_elements[0]}:username")
      },
      :created_at => status_elements[1],
      :message => status_elements[2, status_elements.length].join("")
    }
  end
end
