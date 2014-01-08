require 'rdf/vocab/faogeopol'
require 'rdf/vocab/bibo'

class ThemeRepository < AbstractRepository

  def get_eldis details
    set_common_details details.merge :type => 'eldis'
    @limit = 1
    @theme_uri = details.fetch(:resource_uri)

    process_one_or_many_results(run_get_query).first
  end

  def get_r4d details
    set_common_details details.merge :type => 'r4d'
    @limit = 1
    @theme_uri = details.fetch(:resource_uri)

    process_one_or_many_results(run_get_query).first
  end

  def get_all details, limit
    set_common_details details
    @limit = limit
    
    query_string = build_base_query
    
    #Rails.logger.info query_string
   
    query   = Tripod::SparqlQuery.new(query_string)
    result  = Tripod::SparqlClient::Query.query(query.query, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)
    
    process_one_or_many_results(graph)
  end
  
  private
  
  def construct
    <<-ENDCONSTRUCT.strip_heredoc
    #{common_prefixes}

    CONSTRUCT {
      #{var_or_iriref(@theme_uri)}
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

  def eldis_subquery
    <<-SPARQL.strip_heredoc
    GRAPH <http://linked-development.org/graph/eldis> {
      { 
          #{primary_eldis_select} #{maybe_limit_clause}
      }

      OPTIONAL { 
        #{var_or_iriref(@theme_uri)} skos:narrower ?child_concept .

        ?child_concept 
          dcterms:identifier ?child_id ;
          ?child_predicate ?child_object .
      }
    }
    SPARQL
  end

  def primary_eldis_select
    <<-SPARQL.strip_heredoc
    SELECT * WHERE {
      #{var_or_iriref(@theme_uri)} 
         a skos:Concept ;
         skos:inScheme <http://linked-development.org/eldis/themes/C2/> ;
         rdfs:label ?label ;
         dcterms:identifier ?parent_id .
    }
    SPARQL
  end

  def r4d_subquery
    <<-SPARQL.strip_heredoc
    GRAPH <http://linked-development.org/graph/r4d> {
      {
         #{primary_r4d_select} #{maybe_limit_clause}
      }

      OPTIONAL {
        #{var_or_iriref(@theme_uri)} skos:narrower ?child_concept .
        OPTIONAL { ?child_concept skos:prefLabel ?child_label . }
        OPTIONAL { ?child_concept skos:preLabel ?child_label . }
        BIND(replace(str(?child_concept), "http://aims.fao.org/aos/agrovoc/", '') AS ?child_id) .
      }
    }
    SPARQL
  end

  def primary_r4d_select
    <<-SPARQL.strip_heredoc
         SELECT * WHERE {
            #{var_or_iriref(@theme_uri)} a skos:Concept .
   
            BIND(replace(str(#{var_or_iriref(@theme_uri)}), "(http://aims.fao.org/aos/agrovoc/|http://dbpedia.org/resource/)", '') AS ?parent_id)
      
            OPTIONAL { #{var_or_iriref(@theme_uri)} skos:prefLabel ?label . }
            OPTIONAL { #{var_or_iriref(@theme_uri)} skos:preLabel ?label . }
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
    theme_res = @theme_uri ? RDF::URI.new(@theme_uri) : :theme_uri

    theme_solutions = RDF::Query.execute(graph) do |q| 
      q.pattern [theme_res, RDF::RDFS.label,    :label]
      q.pattern [theme_res, RDF::DC.identifier, :_object_id]
    end.limit(@limit)

    theme_solutions
  end

  def process_each_result graph, current_theme
      theme = { }

      parent_uri = @theme_uri ? RDF::URI.new(@theme_uri) : current_theme.theme_uri
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
           'linked_data_url' => s.child_uri.to_s,
           'metadata_url' => @metadata_url_generator.theme_url(@type, s._object_id.value) }
        end
        
        theme['children_object_array'] = {'child' => child_themes } if child_themes.any?
      end
      theme
  end

  def totalise_query
    query_pattern = if @type == 'r4d'
                      graphise('r4d', primary_r4d_select)
                    elsif @type == 'eldis'
                      graphise('eldis', primary_eldis_select)
                    else # all
                      unionise(graphise('eldis', primary_eldis_select), graphise('r4d', primary_r4d_select))
                    end
    
    <<-SPARQL.strip_heredoc
    #{common_prefixes}

    SELECT (COUNT(#{var_or_iriref(@theme_uri)}) AS ?total) WHERE { 
       #{query_pattern}
    }
    SPARQL
  end
end
