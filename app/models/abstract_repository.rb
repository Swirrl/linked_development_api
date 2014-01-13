class AbstractRepository

  def common_prefixes
      <<-PREFIXES.strip_heredoc
      PREFIX dcterms: <http://purl.org/dc/terms/>
      PREFIX bibo: <http://purl.org/ontology/bibo/>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
      PREFIX fao: <http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/>
      PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>
      PREFIXES
  end

  def initialize
    @metadata_url_generator = MetadataURLGenerator.new("http://linked-development.org")
  end

  # expects a get_all query to have been run first.
  def total_results_of_last_query 
    raise StandardError, 'A get_all query must have been run before calling this method.' if @type == nil

    result = Tripod::SparqlClient::Query.select totalise_query
    result[0]['total']['value'].to_i
  end

  protected

  def set_common_details details, opts=nil
    raise StandardError, "Opts must be an options Hash or nil not #{opts.class}" unless (opts.class == NilClass || opts.class == Hash)
    @type = details.fetch(:type)
    @detail = details.fetch(:detail)
    @resource_uri = details[:resource_uri]
    raise StandardError, 'No resource_uri was supplied.' if opts.present? && opts[:raise_on_nil_resource_uri] && @resource_uri.nil? 
    @limit = parse_limit opts
    @offset = parse_offset opts
  end
  
  def build_base_query
    <<-SPARQL.strip_heredoc
      #{common_prefixes}

      #{construct}
      #{where_clause}
    SPARQL
  end

  # TODO consider whether this should be here or in ThemeRepository,
  # as it's currently overriden in DocumentRepository.
  def where_clause
    raise StandardError, 'Define #where_clause in subclass'
  end

  def maybe_limit_clause
    @limit.present? ? " LIMIT #{@limit}" : ''
  end

  def maybe_offset_clause
    @limit.present? && @offset.present? ? " OFFSET #{@offset}" : ''
  end

  # Generates a string that conforms to a VarOrIRIref in the SPARQL
  # grammar.  If the supplied argument is nil then we return a string
  # of '?resource' othewise we return a SPARQL IRIRef (i.e. a '<URI>'
  # string.)
  def var_or_iriref maybe_uri
    if maybe_uri
      "<#{maybe_uri}>"
    else
      "?resource"
    end
  end

  def process_one_or_many_results graph
    initial_solutions = get_solutions_from_graph graph
    
    initial_solutions.reduce([]) do |results, current_result|
      results << process_each_result(graph, current_result)
    end
  end

  def get_solutions_from_graph graph
    raise StandardError, 'Subclasses should implement this method.'
  end

  def process_each_result graph, current_result
    raise StandardError, 'Subclasses should implement this method.'
  end

  def totalise_query
    raise StandardError, 'Subclasses should implement this #totalise_query method to support #total_results'
  end

  # Builds a union query out of the supplied sub query strings
  def unionise *sub_queries
    sub_queries_with_parens = sub_queries.map do |i| 
      "{ #{i} }" 
    end

    sub_queries_with_parens.join(' UNION ')
  end

  def graphise graph_slug, query
    <<SPARQL 
GRAPH <http://linked-development.org/graph/#{graph_slug}> {  
    #{query} 
}
SPARQL
  end

  # wrap in a WHERE clause
  def whereise query_str
    <<-SPARQL.strip_heredoc
    WHERE {
       #{query_str}
    }
    SPARQL
  end

  def parse_limit opts
    (opts == nil || opts[:limit] == nil) ? 10 : Integer(opts[:limit])
  end

  def parse_offset opts
    (opts == nil || opts[:offset] == nil) ? 0 : Integer(opts[:offset])
  end

end
