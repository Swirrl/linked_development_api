class ResearchOutputController < ApplicationController

  before_filter :make_service
  
  # Note research_outputs are slightly different from the others,
  # which is why they're wrapped in their own controller.
  #
  # Requesting a get research_output by an id, e.g. 'GB-1-203193' can
  # still return many results as a single id can be associated with
  # multiple projects.
  
  def get
    @research_output = @service.get({type: params[:graph], detail: params[:detail], id: params[:id]}, 
                                    host: request.env["HTTP_HOST"], limit: params[:num_results], offset: params[:start_offset])
    
    respond_with @research_output
  end

  def get_all
    @research_output = @service.get_all({type: params[:graph], detail: params[:detail]},
                                        host: request.env["HTTP_HOST"], limit: params[:num_results], offset: params[:start_offset])
    
    respond_with @research_output
  end

  private

  def make_service
    @service = ResearchOutputService.build
  end
  
  
end
