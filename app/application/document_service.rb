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

  def get(details)
    # The original DefaultQueryBuilder#createQuery uses FROM clauses
    # to restrict the results, which we're not re-implementing here yet
    # Silly hash re-structuring on purpose for now
    result = @repository.find(
      type:   details.fetch(:type),
      id:     details.fetch(:id),
      detail: details.fetch(:detail),
    )

    wrap_result(result)
  end

  def get_all details, limit=nil
    type = details.fetch(:type)
    raise InvalidDocumentType unless graph_valid? type

    results = @repository.get_all details, parse_limit(limit)
    
    wrap_results(results)
  end

end
