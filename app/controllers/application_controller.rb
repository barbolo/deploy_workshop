class ApplicationController < ActionController::Base
  protect_from_forgery

  #
  # This action can be used by other applications to check if the server
  # is still up and responding. Currently, it is used in the "health check"
  # configuration of the Amazon Load Balancer.
  #
  def ping
    render :text => "#{Time.now}: OK"
  end

end
