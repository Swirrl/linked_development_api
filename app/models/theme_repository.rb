require 'rdf/vocab/faogeopol'
require 'rdf/vocab/bibo'

class ThemeRepository < AbstractRepository

  def set_details details
    @type = details.fetch(:type)
    @theme_uri = details.fetch(:resource_uri)
    @detail = details.fetch(:detail)
  end
  
  def initialize
    @metadata_url_generator = MetadataURLGenerator.new("http://linked-development.org")
  end
  
  def run_eldis_query details
    set_details details.merge :type => 'eldis'
    map_graph_to_document(run_get_query)
  end

  def run_r4d_query details
    set_details details.merge :type => 'r4d'
    map_graph_to_document(run_get_query)
  end
  
  private

  def run_get_query
    query_string = <<-SPARQL
#{AbstractRepository.common_prefixes}


CONSTRUCT {
  <#{@theme_uri}> 
    rdfs:label ?label ; 
    dcterms:identifier ?parent_id ;
    skos:narrower ?child_concept .
  
  ?child_concept 
    dcterms:identifier ?child_id ;
    ?child_predicate ?child_object .

} WHERE {
  {
    GRAPH <http://linked-development.org/graph/r4d> {

      <#{@theme_uri}> 
           a skos:Concept .
      BIND(replace(str(<#{@theme_uri}>), "(http://aims.fao.org/aos/agrovoc/|http://dbpedia.org/resource/)", '') AS ?parent_id)

      OPTIONAL { <#{@theme_uri}> skos:prefLabel ?label . }
      OPTIONAL { <#{@theme_uri}> skos:preLabel ?label . }


      OPTIONAL {
        <#{@theme_uri}> skos:narrower ?child_concept .
        BIND(replace(str(?child_concept), "http://aims.fao.org/aos/agrovoc/", '') AS ?child_id) .
        ?child_concept ?child_predicate ?child_object ;
        FILTER NOT EXISTS { ?child_concept skos:narrower ?something }
      }
    }
  } UNION {
    GRAPH <http://linked-development.org/graph/eldis> {
      <#{@theme_uri}> 
        a skos:Concept ;
        rdfs:label ?label ;
        dcterms:identifier ?parent_id .
      
      OPTIONAL { 
        <#{@theme_uri}> skos:narrower ?child_concept .

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
  
  def map_graph_to_document graph, 
    theme = { }

    theme_res = RDF::URI.new(@theme_uri)
    theme_solutions =
      graph.query(RDF::Query.new do
                    pattern [theme_res, RDF::RDFS.label,    :label]
                    pattern [theme_res, RDF::DC.identifier, :_object_id]
                  end)
    
    theme_solution = theme_solutions.first

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
