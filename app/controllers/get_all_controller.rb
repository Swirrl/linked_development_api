class GetAllController < ApplicationController

  def documents
    get_all_from DocumentService
  end

  def themes
    get_all_from ThemeService
  end

  def countries
    get_all_from CountryService
  end

  def regions
    get_all_from RegionService
  end

  private 

  def get_all_from klass
    service = klass.build
    @document = service.get_all({type: params[:graph], detail: params[:detail]}, 
                                host: request.env["HTTP_HOST"], limit: params[:num_results], offset: params[:start_offset])
    
    respond_with @document
  end

end
