require 'rdf/vocab/faogeopol'
require 'rdf/vocab/bibo'

class ThemeRepository < AbstractRepository

  def set_details details
    @type = details.fetch(:type)
    @detail = details.fetch(:detail)
  end
  
  def initialize
    @metadata_url_generator = MetadataURLGenerator.new("http://linked-development.org")
  end
  
  def get_eldis details
    set_details details.merge :type => 'eldis'
    @limit = 1
    @theme_uri = details.fetch(:resource_uri)

    map_graph_to_document(run_get_query).first
  end

  def get_r4d details
    set_details details.merge :type => 'r4d'
    @limit = 1
    @theme_uri = details.fetch(:resource_uri)

    map_graph_to_document(run_get_query).first
  end

  def get_all details, limit
    set_details details
    @limit = limit
    
    query_string = build_base_query limit

    Rails.logger.info query_string
   
    query   = Tripod::SparqlQuery.new(query_string)
    result  = Tripod::SparqlClient::Query.query(query.query, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)
    
    map_graph_to_document(graph)
  end
  
  private
  
  # Generates a string that conforms to a VarOrIRIref in the SPARQL
  # grammar.  If the supplied argument is nil then we return a string
  # of '?theme_uri' othewise we return a SPARQL IRIRef (i.e. a '<URI>'
  # string.)
  def var_or_iriref maybe_uri
    if maybe_uri
      "<#{maybe_uri}>"
    else
      "?theme_uri"
    end
  end

  def construct
    <<-ENDCONSTRUCT
#{AbstractRepository.common_prefixes}

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

  def build_eldis_base_query
<<-SPARQL
    GRAPH <http://linked-development.org/graph/eldis> {
      { 
        SELECT * WHERE {
          #{var_or_iriref(@theme_uri)} 
             a skos:Concept ;
             skos:inScheme <http://linked-development.org/eldis/themes/C2/> ;
             rdfs:label ?label ;
             dcterms:identifier ?parent_id .
        } #{maybe_limit_clause}
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

  def build_r4d_base_query
<<-SPARQL
    GRAPH <http://linked-development.org/graph/r4d> {
      { 
         SELECT * WHERE {
            #{var_or_iriref(@theme_uri)} a skos:Concept .
   
            BIND(replace(str(#{var_or_iriref(@theme_uri)}), "(http://aims.fao.org/aos/agrovoc/|http://dbpedia.org/resource/)", '') AS ?parent_id)
      
            OPTIONAL { #{var_or_iriref(@theme_uri)} skos:prefLabel ?label . }
            OPTIONAL { #{var_or_iriref(@theme_uri)} skos:preLabel ?label . }
         } #{maybe_limit_clause}
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

  def run_get_query
    query_string = build_base_query

    query   = Tripod::SparqlQuery.new(query_string)
    result  = Tripod::SparqlClient::Query.query(query.query, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    graph
  end

  def map_graph_to_document graph
    theme_res = @theme_uri ? RDF::URI.new(@theme_uri) : :theme_uri
    theme_solutions = RDF::Query.execute(graph) do |q| 
      q.pattern [theme_res, RDF::RDFS.label,    :label]
      q.pattern [theme_res, RDF::DC.identifier, :_object_id]
    end.limit(@limit)

    theme_solutions.reduce([]) do |results, current_theme|
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
      
      results << theme
    end
  end  
end
