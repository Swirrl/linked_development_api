require 'rdf/vocab/faogeopol'
require 'rdf/vocab/bibo'

class ThemeRepository < AbstractRepository

  def get_one
    raise StandardError, 'Use either get_eldis or get_r4d to find a single document'
  end

  def get_eldis details
    set_common_details details.merge(:type => 'eldis'), raise_error_on_nil_resource_uri: true
    @limit = 1

    process_one_or_many_results(run_get_query).first
  end

  def get_r4d details
    set_common_details details.merge(:type => 'r4d'), raise_error_on_nil_resource_uri: true
    @limit = 1

    process_one_or_many_results(run_get_query).first
  end

  def count type, opts
    do_count type, opts do |r| 
      obj_id = r['countableId']['value']
      obj_id.gsub!('/', '')
      {
       'metadata_url' => @metadata_url_generator.theme_url(@type, obj_id),
       'object_id' => obj_id,
       'count' => Integer(r['count']['value']),
       'object_type' => 'theme',
       'level' => 'NPIS',
       'object_name' => r['countableName']['value']
      }
    end
  end
  
  private

  def countable_fragment
    <<-SPARQL.strip_heredoc
      ?document a bibo:Article ;
                a ?articleType .
 
      ?document dcterms:subject ?countable .
      ?countable a skos:Concept .
    SPARQL
  end
  
  def count_query_string
    <<-SPARQL.strip_heredoc
    #{common_prefixes}

    SELECT ?countable ?countableId ?countableName (COUNT(DISTINCT ?document) AS ?count) WHERE {
       #{primary_count_clause}
    } GROUP BY ?countable ?countableId ?countableName #{maybe_limit_clause} #{maybe_offset_clause}
    SPARQL
  end

  def primary_count_clause
    count_documents_fragment = <<-SPARQL.strip_heredoc
      #{countable_fragment}
      #{optional_countable_clauses}
    SPARQL

    apply_graph_type_restriction(count_documents_fragment)
  end
  
  def optional_countable_clauses
    <<-SPARQL.strip_heredoc
      OPTIONAL { ?countable rdfs:label ?countableName }
      OPTIONAL { ?countable skos:prefLabel ?countableName }
      OPTIONAL { ?countable skos:preLabel ?countableName }

      BIND(replace(str(?countable), "(http://aims.fao.org/aos/agrovoc/|http://dbpedia.org/resource/|http://linked-development.org/eldis/themes/)", '') AS ?countableId)
    SPARQL
  end
  
  def construct
    <<-ENDCONSTRUCT.strip_heredoc
    CONSTRUCT {
        #{var_or_iriref(@resource_uri)}
            rdfs:label ?label ; 
            dcterms:identifier ?parent_id ;
            skos:narrower ?child_concept .
      
        ?child_concept 
            dcterms:identifier ?child_id ;
            rdfs:label ?child_label ; 
            ?child_predicate ?child_object .
    } 
    ENDCONSTRUCT
  end

  def where_clause
    child_subqueries = case @type
                         when 'eldis' ; eldis_child_subquery
                         when 'r4d' ; r4d_child_subquery
                       else 
                         <<-SPARQL.strip_heredoc 
                             #{eldis_child_subquery} 
                             #{r4d_child_subquery}
                         SPARQL
                       end
    <<-SPARQL.strip_heredoc
       WHERE {
           {
               #{primary_where_clause} #{maybe_limit_clause} #{maybe_offset_clause}
           } 
           #{child_subqueries}
       }
    SPARQL
  end

  def primary_where_clause #primary_subquery
    primary_clause = case @type
                       when 'eldis' ; eldis_parent_subquery
                       when 'r4d' ; r4d_parent_subquery
                       else unionise(eldis_parent_subquery, r4d_parent_subquery) # all
                     end
    <<-SPARQL.strip_heredoc
        SELECT * WHERE {
           #{primary_clause}
        }
    SPARQL
  end

  def eldis_parent_subquery
    <<-SPARQL.strip_heredoc
    
    GRAPH <http://linked-development.org/graph/eldis> {
        SELECT * WHERE {
            #{var_or_iriref(@resource_uri)} 
                a skos:Concept ;
                skos:inScheme <http://linked-development.org/eldis/themes/C2/> ;
                rdfs:label ?label ;
                dcterms:identifier ?parent_id .
        }
    }
    SPARQL
  end

  def eldis_child_subquery
    <<-SPARQL.strip_heredoc
      OPTIONAL {
          GRAPH <http://linked-development.org/graph/eldis> {
              #{var_or_iriref(@resource_uri)} skos:narrower ?child_concept .
        
              ?child_concept 
                  dcterms:identifier ?child_id ;
                  ?child_predicate ?child_object .
          }
      }
    SPARQL
  end

  def r4d_child_subquery
    <<-SPARQL.strip_heredoc
      OPTIONAL {
          GRAPH <http://linked-development.org/graph/r4d> {
              #{var_or_iriref(@resource_uri)} skos:narrower ?child_concept .
            
              OPTIONAL { ?child_concept skos:prefLabel ?child_label . }
              OPTIONAL { ?child_concept skos:preLabel ?child_label . }
              BIND(replace(str(?child_concept), "http://aims.fao.org/aos/agrovoc/", '') AS ?child_id) .
          }
      }
    SPARQL
  end

  def r4d_parent_subquery
    <<-SPARQL.strip_heredoc
         SELECT * WHERE {
             GRAPH <http://linked-development.org/graph/r4d> {
                 #{var_or_iriref(@resource_uri)} a skos:Concept .
       
                 BIND(replace(str(#{var_or_iriref(@resource_uri)}), "(http://aims.fao.org/aos/agrovoc/|http://dbpedia.org/resource/)", '') AS ?parent_id)
          
                 OPTIONAL { #{var_or_iriref(@resource_uri)} skos:prefLabel ?label . }
                 OPTIONAL { #{var_or_iriref(@resource_uri)} skos:preLabel ?label . }
             }
         }
       SPARQL
  end

  def run_get_query
    query_string = build_base_query

    query   = Tripod::SparqlQuery.new(query_string)
    result  = Tripod::SparqlClient::Query.query(query.query, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    graph
  end

  def get_solutions_from_graph graph
    theme_res = @resource_uri ? RDF::URI.new(@resource_uri) : :theme_uri

    # don't offset here as this is just a subset of the results from the server
    theme_solutions = RDF::Query.execute(graph) do |q| 
      q.pattern [theme_res, RDF::RDFS.label,    :label]
      q.pattern [theme_res, RDF::DC.identifier, :_object_id]
    end.limit(@limit)

    theme_solutions
  end

  def process_each_result graph, current_theme
      theme = { }

      parent_uri = @resource_uri ? RDF::URI.new(@resource_uri) : current_theme.theme_uri
      theme['linked_data_uri'] = parent_uri.to_s
      theme['object_id'] = current_theme._object_id.value
      theme['object_type'] = 'theme'
      theme['title'] = current_theme.label.value
      theme['metadata_url'] = @metadata_url_generator.theme_url(@type, current_theme._object_id)

      if @detail === 'full'
        theme['site'] = @type
        theme['children_url'] = @metadata_url_generator.children_url(@type, current_theme._object_id)
        theme['name'] = current_theme.label.value # TODO - do we need to return name as well as title?
        
        child_solutions = RDF::Query.execute(graph) do |q|
          q.pattern [parent_uri, RDF::SKOS.narrower, :child_uri]
          q.pattern [:child_uri, RDF::RDFS.label,    :label]
          q.pattern [:child_uri, RDF::DC.identifier, :_object_id]
        end

        child_themes = child_solutions.map do |s|
          {'object_name' => s.label.value,
           'level' => '1', # TODO generate level
           'object_id' => s._object_id.value,
           'linked_data_uri' => s.child_uri.to_s,
           'metadata_url' => @metadata_url_generator.theme_url(@type, s._object_id.value) }
        end
        
        theme['children_object_array'] = {'child' => child_themes } if child_themes.any?
      end
      theme
  end

end
