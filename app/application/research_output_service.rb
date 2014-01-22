require 'exceptions'

class ResearchOutputService < AbstractService
  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(repository: ResearchOutputRepository.new)
    end
  end

  def initialize(dependencies = {})
    super dependencies
    @valid_graphs = %w[all r4d]
  end
  
  def get details, opts
    set_instance_vars details
    validate 

    # Only r4d provides research outputs
    result = @repository.get_r4d(details)
    
    base_url = Rails.application.routes.url_helpers.get_research_outputs_url(@type, {:host => opts[:host], :format => :json, :detail => @detail, :id => details[:id]})
    
    wrap_results(result, base_url)
  end
  
  def get_all details, opts
    results = do_get_all details, opts

    base_url = Rails.application.routes.url_helpers.get_all_research_outputs_url(@type, {:host => opts[:host], :format => :json, :detail => @detail})
    wrap_results results, base_url
  end

  private

  def graph_valid? 
    %w[r4d all].include?(@type)
  end
end
