class GetController < ApplicationController
  
  # Eg http://localhost:3000/openapi/eldis/get/documents/A64559/full
  def documents
    get_it_from DocumentService
  end
  
  # Eg http://localhost:3000/openapi/eldis/get/themes/C782/full
  def themes
    get_it_from ThemeService
  end

  def countries
    get_it_from CountryService
  end

  def regions
    get_it_from RegionService
  end

  def research_outputs
    get_it_from ResearchOutputService
  end
  
  private
  
  def get_it_from klass
    service = klass.build
    @document = service.get(type: params[:graph], id: params[:id], detail: params[:detail])
    
    respond_with @document
  end
end
