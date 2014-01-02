require 'exceptions'

class ApplicationController < ActionController::Base
  respond_to :xml, :json

  rescue_from LinkedDevelopmentError, :with => :invalid_parameters
  rescue_from DocumentNotFound, :with => :document_not_found

  protect_from_forgery

  protected
  def invalid_parameters ex
    respond_with({:error => ex.message}, :status => 400)
  end
  
  def document_not_found ex
    respond_with({:error => ex.message}, :status => 404)
  end
end
