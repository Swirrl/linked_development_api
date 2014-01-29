module Getable
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

  def get_solutions_from_graph graph
    raise StandardError, 'Subclasses should implement the method #get_solutions_from_graph.'
  end

  def process_one_or_many_results graph
    initial_solutions = get_solutions_from_graph graph
    
    initial_solutions.reduce([]) do |results, current_result|
      results << process_each_result(graph, current_result)
    end
  end

  def process_each_result graph, current_result
    raise StandardError, 'Subclasses should implement the method #process_each_result.'
  end

  def build_base_query clauses=nil
    clauses = clauses.present? ? clauses : where_clause

    <<-SPARQL.strip_heredoc
      #{common_prefixes}

      #{construct}
      #{clauses}
    SPARQL
  end

  def construct
    raise StandardError, 'Subclasses should provide a #construct method in order to use #build_base_query'
  end

  # TODO consider whether this should be here or in ThemeRepository,
  # as it's currently overriden in DocumentRepository.
  def where_clause
    raise StandardError, 'Define #where_clause in subclass'
  end
  
end
