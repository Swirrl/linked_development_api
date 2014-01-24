class ErrorsController < ApplicationController

  def not_found
    if env["ORIGINAL_FULLPATH"] =~ /^\/openapi/
      render :json => {:error => "This route cannot be handled."}.to_json, :status => 404
    else
      render :text => "404 Not found", :status => 404 # You can render your own template here
    end
  end
 
  def error
    if env["ORIGINAL_FULLPATH"] =~ /^\/openapi/
      render :json => {:error => "An unknown error occured."}.to_json, :status => 500
    else
      render :text => "500 Server Error", :status => 500 # You can render your own template here
    end
  end
 
  protected
 
  # The exception that resulted in this error action being called can be accessed from
  # the env. From there you can get a backtrace and/or message or whatever else is stored
  # in the exception object.
  def the_exception
    @e ||= env["action_dispatch.exception"]
  end
end
