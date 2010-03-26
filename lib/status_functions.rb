module StatusFunctions
  def status_data(status = nil)
    return nil unless status
    status_elements = status.split("|")
    return { 
      :id => status_elements[1], 
      :user => { 
        :id => status_elements[2], 
        :name => @redis.get("uid:#{status_elements[2]}:username")
      },
      :created_at => status_elements[0],
      :message => status_elements[3, status_elements.length].join("")
    }
  end
end
