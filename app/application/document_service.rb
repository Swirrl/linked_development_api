require 'exceptions'

class DocumentService < AbstractService
  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(document_repository: DocumentRepository.new)
    end
  end

  def initialize(dependencies = { })
    @repository = dependencies.fetch(:document_repository)
  end

  def get details
    # The original DefaultQueryBuilder#createQuery uses FROM clauses
    # to restrict the results, which we're not re-implementing here yet
    # Silly hash re-structuring on purpose for now
    set_instance_vars details
    validate 
    merge_uri_with! details
    
    result = @repository.find(details)

    wrap_result(result)
  end

  def get_all details, opts=nil
    set_instance_vars details, opts
    validate 
    
    results = @repository.get_all details, opts
    
    wrap_results(results)
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
