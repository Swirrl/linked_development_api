class SearchController < ApplicationController

  def search
    service = DocumentService.build

    graph_type = params[:graph]
    detail = params[:detail]

    query_parameters = merge_present_params(params)
    
    if(query_parameters[:q] || query_parameters[:theme] || query_parameters[:country] || query_parameters[:region] || query_parameters[:iati])
      @document = service.search(graph_type, query_parameters, detail,
                                 {host: request.env["HTTP_HOST"], limit: params[:num_results], offset: params[:start_offset]})
      respond_with @document
    else
      respond_with(error_message("You have not included any search parameters.  You must include at least one search parameter of 'q', 'theme', 'region', 'country' or 'iati-identifier'."), :status => 400)
    end
  end

  private

  def merge_present_params params
    query_parameters = {}

    query_parameters.merge!(:q => params[:q],
                            :theme => params[:theme],
                            :country => params[:country],
                            :region => params[:region],
                            :iati => params['iati-identifier'])

    query_parameters.delete_if { |k, v| v.nil? || v.empty? }
    query_parameters
  end
end
