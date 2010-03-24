ActionController::Routing::Routes.draw do |map|

  map.top '/', :controller => :user, :action => :home

  map.public_timeline '/public_timeline', :controller => :status, :action => :public_timeline

  map.login '/login', :controller => :user, :action => :login
  map.logout '/logout', :controller => :user, :action => :logout


  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
