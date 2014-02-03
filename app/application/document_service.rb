require 'exceptions'

class DocumentService < AbstractService
  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(repository: DocumentRepository.new)
    end
  end

  def get_all details, opts
    results = do_get_all details, opts
    
    base_url = Rails.application.routes.url_helpers.get_all_documents_url(@type, {:host => opts[:host], :format => :json, :detail => @detail})
    wrap_results(results, base_url)
  end
  
  def search graph_type, search_parameters, detail, pagination_parameters
    @type = graph_type
    @detail = detail
    set_pagination_parameters pagination_parameters
    validate

    base_url = Rails.application.routes.url_helpers.search_documents_url(@type, search_parameters.merge({:host => pagination_parameters[:host], :format => :json, :detail => @detail}))

    results = @repository.search(graph_type, search_parameters, detail, pagination_parameters)
    wrap_results(results, base_url)
  end
  
  private 

  def convert_id_to_uri doc_id
    # From the original GetQueryBuilder->createQuery
    # (This appears to be hard-coded to eldis URIs only)

    # Maybe find a better implementation than the original?
    # This seems unnecessarily coupled to the id format and
    # will fail if we have another digits-only id format.
    #
    # PHP: For now we base graph selection on the ID.
    #      ELDIS IDs start with A, whereas R4D are numerical.
    #      Graph will already be respected by the graph query.
    if is_eldis_id? doc_id
      "http://linked-development.org/eldis/output/#{doc_id}/"
    else
      "http://linked-development.org/r4d/output/#{doc_id}/"
    end
  end
  
  def is_eldis_id? document_id
    document_id =~ /^A/
  end
end
