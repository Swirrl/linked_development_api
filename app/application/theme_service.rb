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

    resource_uri = theme_uri(doc_id)

    details.merge! :resource_uri => resource_uri

    result = if type == 'eldis' && is_eldis_id?(doc_id)
               @theme_repository.run_eldis_query details
             elsif type == 'r4d' && is_agrovoc_id?(doc_id) 
               @theme_repository.run_r4d_query details
             elsif type == 'all'
                 if is_dbpedia_id?(doc_id) || is_agrovoc_id?(doc_id)
                   @theme_repository.run_r4d_query details 
                 elsif is_eldis_id?(doc_id)
                   @theme_repository.run_eldis_query details 
                 else
                   raise LinkedDevelopmentError, "Unexpected :id format."
                 end
             else
               raise LinkedDevelopmentError, "Invalid :id format with graph type #{type}"
             end
   
    {
      "results" => [result]
    }
  end

  def check_graph_validity? graph
    raise InvalidDocumentType unless %w[eldis r4d all].include?(graph)
  end

  private

  def is_eldis_id? identifier
    identifier =~ /^C\d{1,}$/
  end

  def is_agrovoc_id? identifier
    identifier =~ /^c_\d{1,}$/
  end

  def is_dbpedia_id? identifier
    !is_eldis_id?(identifier) && !is_agrovoc_id?(identifier)
  end

  # Generate a resource URI for the theme, note this is different from a 'metadata_url'
  def theme_uri doc_id
    if is_eldis_id? doc_id
      "http://linked-development.org/eldis/themes/#{doc_id}/"
    elsif is_agrovoc_id? doc_id
      "http://aims.fao.org/aos/agrovoc/#{doc_id}"
    else is_dbpedia_id? doc_id
      "http://dbpedia.org/resource/#{doc_id}"
    end
  end
  
end
