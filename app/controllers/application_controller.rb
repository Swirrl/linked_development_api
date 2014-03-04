require 'exceptions'

class ApplicationController < ActionController::Base
  respond_to :xml, :json

  rescue_from LinkedDevelopmentError, :with => :invalid_parameters
  rescue_from DocumentNotFound, :with => :document_not_found

  before_filter :check_maintainance_mode

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

  def check_maintainance_mode
    if Pathname.new(LinkedDevelopmentApi::CRAWL_IN_PROGRESS_FILE_PATH).exist?
      respond_with(error_message("The site is currently down as we update our data, please try again soon."), :status => 503)
    end
  end

end
