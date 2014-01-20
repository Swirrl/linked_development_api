require 'exceptions'

class ResearchOutputRepository < AbstractRepository

  def get_one details
    # r4d works off object_id because the URI is not conveniently
    # slugged for us.

    set_common_details details, raise_error_on_nil_resource_uri: false
    @limit = 1

    query_string = build_base_query
    Rails.logger.debug query_string

    result  = Tripod::SparqlClient::Query.query(query_string, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    process_one_or_many_results(graph).first
  end
  
  
  def construct 
    <<-CONSTRUCT.strip_heredoc
      CONSTRUCT {
        ?resource dcterms:title ?title ;
                  a dbpo:ResearchProject ;
                  dcterms:identifier ?projectId .
        
        ?output dcterms:title ?outputTitle ;
                bibo:uri ?outputLink ;
                dcterms:date ?outputDate ;
                dcterms:isPartOf ?resource .
        
      }
    CONSTRUCT
  end

  def where_clause
    <<-SPARQL
    {
      {  
         SELECT DISTINCT ?resource ?title ?projectUri ?projectId WHERE {
           ?resource a dbpo:ResearchProject ;
                a <http://www.iatistandard.org/ontology#iati-activity> ;
                dcterms:title ?title ;
                dcterms:identifier #{var_or_literal(@resource_id, '?projectId')} ;
                dcterms:identifier ?projectId .
    
           FILTER(regex(str(?projectId), "^[0-9]+", "i"))
        }
      }    
    
      {
        SELECT DISTINCT ?output #{uri_or_as(@resource_uri)} ?outputTitle ?outputDate ?outputLink WHERE {
        
          ?output dcterms:isPartOf ?resource ;
              dcterms:title ?outputTitle ;
              dcterms:date ?outputDate .
    
          BIND(replace(str(?output), "http://linked-development.org/r4d/output/", '') AS ?outputUriId)
          BIND(replace(str(?outputUriId), "/", '') AS ?outputId)
          BIND(CONCAT("http://r4d.dfid.gov.uk/output/", ?outputId, "/") AS ?outputLink)
        }
      }
    }
    SPARQL
  end

  private 

  def get_solutions_from_graph graph
    # don't offset here as this is just a subset of the results from the server
    research_projects_solutions = RDF::Query.execute(graph) do |q| 
      q.pattern [:research_project, RDF::DC.title,    :title]
      q.pattern [:research_project, RDF::DC.identifier, :_object_id]
    end.limit(@limit)

    research_projects_solutions
  end

  def process_each_result graph, current_project
    project = { }

    parent_uri = current_project.research_project.to_s

    project['title'] = current_project.title.value
    project['object_id'] = current_project._object_id.value
    project['object_type'] = 'research_project' 
    #project['metadata_url'] = @metadata_url_generator.country_url(current_project.graph_name.value, current_project._object_id.value)
    project['linked_data_uri'] = parent_uri.to_s
    
    project
  end
end
