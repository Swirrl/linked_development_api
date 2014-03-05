class CountController < ApplicationController

  def themes
    get_it_from ThemeService
  end

  def regions
    get_it_from RegionService
  end

  def countries
    get_it_from CountryService
  end

  private

  def get_it_from klass
    service = klass.build
    @document = service.count({:type => params[:graph]},
                              {host: request.env["HTTP_HOST"], limit: params[:num_results], offset: params[:start_offset], format: params[:format]})

    respond_with @document
  end

end
