require 'exceptions'

class ApplicationController < ActionController::Base
  respond_to :xml, :json
  rescue_from LinkedDevelopmentError, :with => :invalid_parameters

  protect_from_forgery

  protected
  def invalid_parameters ex
    respond_with({:error => ex.message}, :status => 400)
  end
end
