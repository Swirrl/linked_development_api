class GetController < ApplicationController
  
  # Eg http://localhost:3000/openapi/eldis/get/documents/A64559/full
  def documents
    service = DocumentService.build
    @document = service.get(type: params[:graph], id: params[:id], detail: params[:detail])

    respond_with @document
  end
  
  # Eg http://localhost:3000/openapi/eldis/get/themes/C782/full
  def themes
    service = ThemeService.build
    @document = service.get(type: params[:graph], id: params[:id], detail: params[:detail])
    
    respond_with @document
  end
end
