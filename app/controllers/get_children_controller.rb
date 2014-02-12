class GetChildrenController < ApplicationController
  def themes
    service = ThemeService.build
    @results = service.get_children({type: params[:graph], id: params[:id], detail: params[:detail]},
                                    {host: request.env["HTTP_HOST"], limit: params[:num_results], offset: params[:start_offset]})
    respond_with @results
  end
end
