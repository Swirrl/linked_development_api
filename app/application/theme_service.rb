require 'exceptions'

class ThemeService
  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(
        theme_repository:    ThemeRepository.new,
        metadata_url_generator: MetadataURLGenerator.new("http://linked-development.org")
      )
    end
  end

  def initialize(dependencies = { })
    @theme_repository    = dependencies.fetch(:theme_repository)
    @metadata_url_generator = dependencies.fetch(:metadata_url_generator)
  end

  def get(details)
    # The original DefaultQueryBuilder#createQuery uses FROM clauses
    # to restrict the results, which we're not re-implementing here yet
    # Silly hash re-structuring on purpose for now

    type = details.fetch(:type)
    
    check_graph_validity? type
    
    result = @theme_repository.find(type: type,
                                    id: details.fetch(:id),
                                    detail: details.fetch(:detail),
                                    metadata_url_generator: @metadata_url_generator)
    {
      "results" => [result]
    }
  end

  def check_graph_validity? graph
    raise InvalidDocumentType unless %w[eldis r4d all].include?(graph)
  end
  
end
