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
    @theme_uri = details.fetch(:resource_uri)

    map_graph_to_document(run_get_query)
  end

  def get_r4d details
    set_details details.merge :type => 'r4d'
    @theme_uri = details.fetch(:resource_uri)

    map_graph_to_document(run_get_query)
  end

  def get_all details
    set_details details
    # TODO
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

  def run_get_query
    query_string = <<-SPARQL
#{AbstractRepository.common_prefixes}

CONSTRUCT {
  #{var_or_iriref(@theme_uri)}
    rdfs:label ?label ; 
    dcterms:identifier ?parent_id ;
    skos:narrower ?child_concept .
  
  ?child_concept 
    dcterms:identifier ?child_id ;
    ?child_predicate ?child_object .

} WHERE {
  {
    GRAPH <http://linked-development.org/graph/r4d> {

      #{var_or_iriref(@theme_uri)}
           a skos:Concept .
      BIND(replace(str(#{var_or_iriref(@theme_uri)}), "(http://aims.fao.org/aos/agrovoc/|http://dbpedia.org/resource/)", '') AS ?parent_id)

      OPTIONAL { #{var_or_iriref(@theme_uri)} skos:prefLabel ?label . }
      OPTIONAL { #{var_or_iriref(@theme_uri)} skos:preLabel ?label . }

      OPTIONAL {
        #{var_or_iriref(@theme_uri)} skos:narrower ?child_concept .
        BIND(replace(str(?child_concept), "http://aims.fao.org/aos/agrovoc/", '') AS ?child_id) .
        ?child_concept ?child_predicate ?child_object ;
        FILTER NOT EXISTS { ?child_concept skos:narrower ?something }
      }
    }
  } UNION {
    GRAPH <http://linked-development.org/graph/eldis> {
      #{var_or_iriref(@theme_uri)} 
        a skos:Concept ;
        rdfs:label ?label ;
        dcterms:identifier ?parent_id .
      
      OPTIONAL { 
        #{var_or_iriref(@theme_uri)} skos:narrower ?child_concept .

        ?child_concept 
          dcterms:identifier ?child_id ;
          ?child_predicate ?child_object .

        FILTER NOT EXISTS { ?child_concept skos:narrower ?something }
      }
    }
  }
}
SPARQL

    #puts query_string
    
    query   = Tripod::SparqlQuery.new(query_string)
    result  = Tripod::SparqlClient::Query.query(query.query, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    graph
  end

  # TODO generalise this for get_all
  def map_graph_to_document graph
    theme = { }

    theme_res = RDF::URI.new(@theme_uri)
    theme_solutions =
      graph.query(RDF::Query.new do
                    pattern [theme_res, RDF::RDFS.label,    :label]
                    pattern [theme_res, RDF::DC.identifier, :_object_id]
                  end)
    
    theme_solution = theme_solutions.first

    return nil unless theme_solution.present?

    theme['linked_data_uri'] = @theme_uri
    theme['object_id'] = theme_solution._object_id.value
    theme['object_type'] = 'theme'
    theme['title'] = theme_solution.label.value
    theme['metadata_url'] = @metadata_url_generator.theme_url(@type, theme_solution._object_id)

    if @detail === 'full'
      theme['site'] = @type
      theme['children_url'] = @metadata_url_generator.children_url(@type, theme_solution._object_id)
      theme['name'] = theme_solution.label.value
      
      child_solutions = RDF::Query.execute(graph) do |q|
        q.pattern [:theme, RDF::RDFS.label,    :label]
        q.pattern [:theme, RDF::DC.identifier, :_object_id]
      end

      filtered_solutions = []
      child_solutions.each do |s|
        filtered_solutions << {
          'object_name' => s.label.value,
          'level' => '1',
          'object_id' => s._object_id.value,
          'linked_data_url' => s.theme.to_s,
          'metadata_url' => @metadata_url_generator.theme_url(@type, s._object_id.value)
        } unless s.theme.to_s === @theme_uri
      end
 
      theme['children_object_array'] = {'child' => filtered_solutions } if filtered_solutions.any?
    end
    
    theme
  end  
end
