class DocumentService
  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(
        document_repository:    DocumentRepository.new,
        metadata_url_generator: MetadataURLGenerator.new("http://linked-development.org")
      )
    end
  end

  def initialize(dependencies = { })
    @document_repository    = dependencies.fetch(:document_repository)
    @metadata_url_generator = dependencies.fetch(:metadata_url_generator)
  end

  def get(details)
    # The original DefaultQueryBuilder#createQuery uses FROM clauses
    # to restrict the results, which we're not re-implementing here yet
    # Silly hash re-structuring on purpose for now
    result = @document_repository.find(
      type:   details.fetch(:type),
      id:     details.fetch(:id),
      detail: details.fetch(:detail),

      metadata_url_generator: @metadata_url_generator
    )

    # TODO un-hardcode this
    {
      "results" => [result],
      "metadata" => {
        "num_results"   => "Unknown",
        "start_offset"  => 0
      }
    }
  end
end
