class GetAllController < ApplicationController

  def documents
    service = DocumentService.build
    @document = service.get_all({type: params[:graph], detail: params[:detail]}, 
                                host: request.env["HTTP_HOST"], limit: params[:num_results], offset: params[:start_offset])
    
    respond_with @document
  end

  def themes
    service = ThemeService.build
    @document = service.get_all({type: params[:graph], detail: params[:detail]}, 
                                host: request.env["HTTP_HOST"], limit: params[:num_results], offset: params[:start_offset])
    
    respond_with @document
  end

end
