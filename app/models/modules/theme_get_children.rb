module ThemeGetChildren
  def get_children details, opts={}
    # this can currently only work with eldis, so force the type.
    set_common_details details.merge(:type => 'eldis'), opts.merge(raise_error_on_nil_resource_uri: true)

    graph = run_get_children_query

    parent = build_parent_result graph

    initial_solutions = get_children_solutions_from_graph graph
    
    initial_solutions.reduce([]) do |results, child_result|
      results << process_each_child(graph, child_result, parent)
    end
  end

  def totalise_get_children
    raise StandardError, 'A get_all query must have been run before calling this method.' if @type == nil

    primary_query_clause = graphise('eldis', "#{var_or_iriref(@resource_uri)} skos:narrower ?child_concept .")
    
    q = <<-SPARQL.strip_heredoc
      SELECT ?child_concept WHERE {
          #{primary_query_clause}
      }
    SPARQL
    
    query_string = totalise_query(q, '?child_concept')

    result = Tripod::SparqlClient::Query.select query_string
    result[0]['total']['value'].to_i
  end

  private
  
  def build_parent_result graph
    parent_uri = RDF::URI.new(@resource_uri)

    parent_obj = {}
    
    parent_solution = RDF::Query.execute(graph) do |q| 
      q.pattern [parent_uri, RDF::RDFS.label,    :label]
      q.pattern [parent_uri, RDF::DC.identifier, :_object_id]
    end.first

    raise LinkedDevelopmentError, "A valid eldis resource :id parameter must be supplied for this request to respond." unless parent_solution.present?
    
    parent_obj['object_name'] = parent_solution.label.value
    parent_obj['object_id'] = parent_solution._object_id.value
    parent_obj['linked_data_uri'] = parent_uri.to_s
    parent_obj['metadata_url'] = @metadata_url_generator.theme_url(@type, parent_solution._object_id)
    parent_obj['object_type'] = 'theme'

    parent_obj
  end

  def get_children_solutions_from_graph graph
    parent_uri = RDF::URI.new(@resource_uri)

    child_solutions = RDF::Query.execute(graph) do |q|
      q.pattern [parent_uri, RDF::SKOS.narrower, :child_uri]
      q.pattern [:child_uri, RDF::RDFS.label,    :label]
      q.pattern [:child_uri, RDF::DC.identifier, :_object_id]
    end.limit(@limit)
    
    child_solutions
  end

  def process_each_child graph, child, parent_obj
    {
     'linked_data_uri' => child.child_uri.to_s,
     'object_id' => child._object_id.value,
     'object_type' => 'theme',
     'title' => child.label.value,
     'metadata_url' => @metadata_url_generator.theme_url(@type, child._object_id.value),
     'site' => 'eldis',
     'children_url' => @metadata_url_generator.children_url(@type, child._object_id.value),
     'name' => child.label.value,     
     'parent_object_array' => {
                               'parent' => [parent_obj]
                              }
    }
  end

  def get_children_primary_query
    q = <<-SPARQL.strip_heredoc
        {
          SELECT * WHERE { 
            #{var_or_iriref(@resource_uri)} skos:narrower ?child_concept .
          } #{maybe_limit_clause} #{maybe_offset_clause}
        }

        #{var_or_iriref(@resource_uri)}
          a skos:Concept ;
          skos:inScheme <http://linked-development.org/eldis/themes/C2/> ;
          rdfs:label ?label ;
          dcterms:identifier ?parent_id .

        ?child_concept dcterms:identifier ?child_id ;
                       ?child_predicate ?child_object .
    SPARQL
    graphise('eldis', q)
  end
  
  def run_get_children_query
    query_string = common_prefixes + construct + whereise(get_children_primary_query)
    Rails.logger.info(query_string)
    query   = Tripod::SparqlQuery.new(query_string)
    result  = Tripod::SparqlClient::Query.query(query.query, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)
    graph
  end
end
