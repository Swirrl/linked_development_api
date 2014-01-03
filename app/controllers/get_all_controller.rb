class GetAllController < ApplicationController

  def themes
    service = ThemeService.build
    @document = service.get_all({type: params[:graph], detail: params[:detail]}, params[:num_results])
    
    respond_with @document
  end

end
