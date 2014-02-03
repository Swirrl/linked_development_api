require 'exceptions'

class ApplicationController < ActionController::Base
  respond_to :xml, :json

  rescue_from LinkedDevelopmentError, :with => :invalid_parameters
  rescue_from DocumentNotFound, :with => :document_not_found

  protect_from_forgery

  def document_not_found ex=nil
    error_doc = ex.present? ? error_message(ex.message) : error_message('The requested object was not found (no such ID).')
    respond_with(error_doc, :status => 404)
  end

  protected
  def invalid_parameters ex
    respond_with(error_message(ex.message), :status => 400)
  end

  def error_message message
    {:error => message}
  end
  
end
