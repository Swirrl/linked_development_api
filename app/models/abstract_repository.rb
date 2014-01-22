class AbstractRepository

  def initialize
    @metadata_url_generator = MetadataURLGenerator.new("http://linked-development.org")
  end

  def get_one details
    set_common_details details, raise_error_on_nil_resource_uri: true
    @limit = 1

    query_string = build_base_query
    Rails.logger.debug query_string

    result  = Tripod::SparqlClient::Query.query(query_string, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    process_one_or_many_results(graph).first
  end

  def get_all details, opts={}
    set_common_details details, opts
    
    query_string = build_base_query
    Rails.logger.debug query_string
    
    result  = Tripod::SparqlClient::Query.query(query_string, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    process_one_or_many_results(graph)
  end

  def common_prefixes
      <<-PREFIXES.strip_heredoc
        PREFIX dcterms: <http://purl.org/dc/terms/>
        PREFIX bibo: <http://purl.org/ontology/bibo/>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        PREFIX fao: <http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>
        PREFIX linkeddev: <#{local_uri('')}>
        PREFIX dbpo: <http://dbpedia.org/ontology/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      PREFIXES
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
    @resource_id = details[:id]
    raise StandardError, 'No resource_uri was supplied.' if opts.present? && opts[:raise_on_nil_resource_uri] && @resource_uri.nil? 
    @limit = parse_limit opts
    @offset = parse_offset opts
  end
  
  def build_base_query clauses=nil
    clauses = clauses.present? ? clauses : where_clause

    <<-SPARQL.strip_heredoc
      #{common_prefixes}

      #{construct}
      #{clauses}
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
  def var_or_iriref maybe_uri, var='?resource'
    if maybe_uri
      "<#{maybe_uri}>"
    else
      var
    end
  end

  # Generates a string that conforms to a VarOrIRIref in the SPARQL
  # grammar.  If the supplied argument is nil then we return a string
  # of '?resource' othewise we return a SPARQL IRIRef (i.e. a '<URI>'
  # string.)
  def var_or_literal maybe_literal, var='?resource'
    if maybe_literal
      "\"#{maybe_literal}\""
    else
      var
    end
  end

  def literal_or_as maybe_literal, var='?resource'
    if maybe_literal 
      "(\"#{maybe_literal}\" AS #{var})"
    else
      var
    end    
  end
  
  def uri_or_as maybe_uri, var='?resource'
    if maybe_uri 
      "(<#{maybe_uri}> AS #{var})"
    else
      var
    end
  end

  def process_one_or_many_results graph
    initial_solutions = get_solutions_from_graph graph
    
    initial_solutions.reduce([]) do |results, current_result|
      results << process_each_result(graph, current_result)
    end
  end

  def get_solutions_from_graph graph
    raise StandardError, 'Subclasses should implement the method #get_solutions_from_graph.'
  end

  def process_each_result graph, current_result
    raise StandardError, 'Subclasses should implement the method #process_each_result.'
  end

  def totalise_query
    raise StandardError, 'Subclasses should implement this #totalise_query method to support #total_results'
  end

  def construct
    raise StandardError, 'Subclasses should provide a #construct method in order to use #build_base_query'
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

  # Use this for coining localised graph uri's.  A bit of a hack, but
  # it lets us generate URI's for construct graphs that only have
  # meaning within this app.
  def local_uri slug
    "http://linked-development.org/dev/#{slug}"
  end

  # Calculate the total results in the query.  Subclasses may need to
  # override this to generate a correct answer.
  def totalise_query
    total_q = <<-SPARQL.strip_heredoc
    #{common_prefixes}
    SELECT (COUNT(DISTINCT ?resource) AS ?total) WHERE { 
      #{primary_where_clause}
    }
    SPARQL
    Rails.logger.info total_q
    total_q
  end

  # Objects that want to reuse totalise_query need to implement this
  # method.  And ensure that ?resource is a SPARQL variable, as this
  # is what we count. This method should avoid using limit/offset, as
  # it needs to return the number of available results.
  def primary_where_clause
    raise StandardError, 'To use #totalise_query, you must implement #primary_where_clause'
  end
end
