class DocumentService
  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(document_repository: DocumentRepository.new)
    end
  end

  def initialize(dependencies = { })
    @document_repository = dependencies.fetch(:document_repository)
  end

  def get(details)
    # The original DefaultQueryBuilder#createQuery uses FROM clauses
    # to restrict the results, which we're not re-implementing here yet
    # Silly hash re-structuring on purpose for now
    result = @document_repository.find(
      type:   details.fetch(:type),
      id:     details.fetch(:id),
      detail: details.fetch(:detail)
    )

    {
      "result" => result,
      "metadata" => {
        "num_results"   => "Unknown",
        "start_offset"  => 0
      }
    }
  end
end