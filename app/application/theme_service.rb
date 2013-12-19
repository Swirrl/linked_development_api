require 'exceptions'

class ThemeService
  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(theme_repository: ThemeRepository.new)
    end
  end

  def initialize(dependencies = { })
    @theme_repository = dependencies.fetch(:theme_repository)
  end

  def get(details)
    # The original DefaultQueryBuilder#createQuery uses FROM clauses
    # to restrict the results, which we're not re-implementing here yet
    # Silly hash re-structuring on purpose for now
    
    type = details.fetch(:type)
    doc_id = details.fetch(:id)

    check_graph_validity? type

    result = if type == 'eldis' || doc_id =~ /^C/
               @theme_repository.run_eldis_query details
             elsif type == 'r4d' || doc_id =~ /^c_/
               @theme_repository.run_r4d_query details
             else
               raise LinkedDevelopmentError, "/:graph/function/object/ parameter must be eldis, r4d or all."
             end
    
   
    {
      "results" => [result]
    }
  end

  def check_graph_validity? graph
    raise InvalidDocumentType unless %w[eldis r4d all].include?(graph)
  end
  
end
