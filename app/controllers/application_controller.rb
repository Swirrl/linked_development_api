require 'exceptions'

class ApplicationController < ActionController::Base
  respond_to :xml, :json

  rescue_from LinkedDevelopmentError, :with => :invalid_parameters
  rescue_from DocumentNotFound, :with => :document_not_found

  before_filter :check_maintainance_mode

  before_filter :redirect_unsupported_format_requests
  before_filter :rewrite_format

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

  # The old PHP code supported HTML views of the JSON code.  If a
  # browser hits one of our URLs without specifying a supported
  # mime-type then we redirect them with a 303 see other to the JSON
  # format.
  def redirect_unsupported_format_requests
    unless request.format.nil? || mimes_for_respond_to.keys.include?(request.format.to_sym)
      param_str = create_query_string(request.query_parameters)

      redirect_to("#{request.path}.json#{param_str}", status: 303)
    end
  end

  # The old PHP API used a &format= query parameter, incoming requests
  # containing this parameter are redirected to the new location where
  # the format follows rails like conventions, i.e. /foo.json
  #
  # Any orginal query parameters baring the old format parameter are
  # preserved.
  def rewrite_format
    qs_format = request.query_parameters[:format]

    if qs_format.present?
      new_params = request.query_parameters.dup
      new_params.delete :format

      param_str = create_query_string(new_params)
      format_already_present = request.path.split('.').count == 2

      # make formats idempotent so /foo.json?format=json doesn't generate /foo.json.json
      if format_already_present
        redirect_to("#{request.path}#{param_str}")
      else
        redirect_to("#{request.path}.#{qs_format}#{param_str}")
      end
    end
  end

  private

  def create_query_string new_params
    new_params.any? ? "?#{Rack::Utils.build_query(new_params)}" : ''
  end

end
