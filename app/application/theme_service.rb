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

  def get details
    # The original DefaultQueryBuilder#createQuery uses FROM clauses
    # to restrict the results, which we're not re-implementing here yet
    # Silly hash re-structuring on purpose for now
    
    type = details.fetch(:type)
    doc_id = details.fetch(:id)
    detail = details[:detail]

    raise LinkedDevelopmentError, 'Detail must be either full, short or unspecified (in which case it defaults to short).' unless detail_valid? detail 
    raise InvalidDocumentType unless graph_valid? type
    
    resource_uri = theme_uri(doc_id)

    details.merge! :resource_uri => resource_uri

    result = if type == 'eldis' && is_eldis_id?(doc_id)
               @theme_repository.get_eldis details
             elsif type == 'r4d' && is_agrovoc_id?(doc_id) 
               @theme_repository.get_r4d details
             elsif type == 'all'
                 if is_dbpedia_id?(doc_id) || is_agrovoc_id?(doc_id)
                   @theme_repository.get_r4d details 
                 elsif is_eldis_id?(doc_id)
                   @theme_repository.get_eldis details 
                 else
                   raise LinkedDevelopmentError, "Unexpected :id format."
                 end
             else
               raise LinkedDevelopmentError, "Invalid :id format (#{doc_id}) with graph type #{type}"
             end

    raise DocumentNotFound, "No resource found with id #{doc_id} not found" if result.nil?

    {
      "results" => [result]
    }
  end

  def get_all details
    type = details.fetch(:type)
    raise InvalidDocumentType unless graph_valid? type

    # TODO
    results = []

    {
      'results' => results 
    }
  end

  def graph_valid? graph
    %w[eldis r4d all].include?(graph)
  end

  def detail_valid? detail
  ['full', 'short', nil].include? detail
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
