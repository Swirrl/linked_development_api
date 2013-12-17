require 'rdf/vocab/faogeopol'
require 'rdf/vocab/bibo'

class ThemeRepository
  def find(details)
    @type = details.fetch(:type)
    @doc_id = details.fetch(:id)
    @detail = details.fetch(:detail)
    @metadata_url_generator = details.fetch(:metadata_url_generator)
    
    @theme_uri = theme_uri(@type, @doc_id)
    
    if @type === 'eldis'
      run_eldis_query 
    end
  end

  def run_eldis_query
    eldis_graph_uri = "http://linked-development.org/graph/eldis"
    theme_uri = theme_uri(@type, @doc_id)
    
    query_string = <<-SPARQL
  PREFIX dcterms: <http://purl.org/dc/terms/>
  PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
  PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
  
  CONSTRUCT {
    <#{@theme_uri}> 
      rdfs:label ?label ; 
      dcterms:identifier  ?id ;
      skos:narrower ?child_concept .
  
    ?child_concept ?child_predicate ?child_object .
  } WHERE {
    GRAPH <#{eldis_graph_uri}> {
      
      <#{@theme_uri}> 
        a skos:Concept ;
        skos:inScheme <http://linked-development.org/eldis/themes/C2/> ;
        rdfs:label ?label ;
        dcterms:identifier ?id ;
        skos:narrower ?child_concept .
    
      ?child_concept ?child_predicate ?child_object ;
        FILTER NOT EXISTS { ?child_concept skos:narrower ?something }
  
    } 
  }
SPARQL

    query   = Tripod::SparqlQuery.new(query_string, uri: eldis_graph_uri)
    result  = Tripod::SparqlClient::Query.query(query.query, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    map_graph_to_document graph
  end

  private

  def map_graph_to_document graph
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
    theme['metadata_url'] = @metadata_url_generator.theme_url('eldis', theme_solution._object_id)

    if @detail === 'full'
      puts 'full'
    end
    
    theme
  end  

  def theme_uri type, doc_id
    "http://linked-development.org/#{type}/themes/#{doc_id}/"
  end
  
end

