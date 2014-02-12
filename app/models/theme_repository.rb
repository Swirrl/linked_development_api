require 'rdf/vocab/faogeopol'
require 'rdf/vocab/bibo'
require_relative './modules/countable/count_by_theme'
require_relative './modules/theme_get_children'

class ThemeRepository < AbstractRepository
  include SparqlHelpers
  include Pageable
  include Getable
  include ThemeGetChildren
  include Totalable
  include CountByTheme
  
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

  private
  
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

  def primary_where_clause
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
