require 'exceptions'

class ResearchOutputRepository < AbstractRepository

  include SparqlHelpers
  include Countable
  include Pageable
  include Getable
  include Totalable
  
  def get_r4d details, opts={}
    # r4d works off object_id because the URI is not conveniently
    # slugged for us.
    @type = 'r4d'

    set_common_details details, opts.merge(raise_error_on_nil_resource_uri: false)

    # TODO support this parameter
    @per_project = opts[:per_project] || 5
    query_string = build_base_query
    Rails.logger.debug query_string

    result  = Tripod::SparqlClient::Query.query(query_string, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    process_one_or_many_results(graph)
  end

  def get_all details, opts={}
    get_r4d details
  end  
  
  def construct 
    <<-CONSTRUCT.strip_heredoc
      CONSTRUCT {
        ?resource dcterms:title ?title ;
                  a dbpo:ResearchProject ;
                  dcterms:identifier ?projectId ;
                  linkeddev:numberOfOutputs ?numberOfOutputs .
      }
    CONSTRUCT
  end

  def primary_where_clause
    <<-SPARQL.strip_heredoc
        SELECT DISTINCT ?resource ?title ?projectUri ?projectId (COUNT(?output) AS ?numberOfOutputs) WHERE {
          ?resource a dbpo:ResearchProject ;
                    a <http://www.iatistandard.org/ontology#iati-activity> ;
                    dcterms:title ?title ;
                    dcterms:identifier #{var_or_literal(@resource_id, '?identifier')} ;
                    dcterms:identifier ?projectId .
          
           FILTER(regex(str(?projectId), "^[0-9]+", "i"))
        
          ?output dcterms:isPartOf ?resource .
        
        } GROUP BY ?resource ?title ?projectUri ?projectId 
    SPARQL
  end
  
  def where_clause
    <<-SPARQL.strip_heredoc
   {
      {  
        #{primary_where_clause} #{maybe_limit_clause} #{maybe_offset_clause}
      }
      
      {
        SELECT ?output2 ?resource2 ?outputTitle ?outputDate ?outputLink ?outputId WHERE {
          ?resource2 a dbpo:ResearchProject ;
                     a <http://www.iatistandard.org/ontology#iati-activity> ;
                     dcterms:title ?title ;
                     dcterms:identifier #{var_or_literal(@resource_id, '?projectId')} ;
                     dcterms:identifier ?projectId2 .
        }
      }
    }
    SPARQL
  end
  
  private 

  def get_solutions_from_graph graph
    # don't offset here as this is just a subset of the results from the server

    numberOfOutputs = RDF::URI.new(local_uri('numberOfOutputs'))
    aResearchProject = RDF::URI.new('http://dbpedia.org/ontology/ResearchProject')
    
    research_projects_solutions = RDF::Query.execute(graph) do |q| 
      q.pattern [:research_project, RDF::DC.title,    :title]
      q.pattern [:research_project, RDF::DC.identifier, :_object_id]
      q.pattern [:research_project, RDF.type, aResearchProject]
      q.pattern [:research_project, numberOfOutputs, :output_count]
    end.limit(@limit)

    research_projects_solutions
  end

  def process_each_result graph, current_project
    project = { }

    parent_uri = current_project.research_project

    project_outputs = run_research_output_query parent_uri

    project['title'] = current_project.title.value
    project['linked_data_uri'] = parent_uri.to_s
    project['link'] = parent_uri.to_s
    project['object_id'] = current_project._object_id.value
    project['object_type'] = 'research_project' 

    project['output_count'] = current_project.output_count.value
    
    child_research_outputs = project_outputs.map do |s|
      {
       'title' => s['outputTitle']['value'],
       'object_type' => 'document',
       'linked_data_uri' => s['output']['value'],
       'link' => s['outputLink']['value'],
       'publication_date' => s['outputDate']['value'].to_s,
       'metadata_url' => @metadata_url_generator.document_url(@type, s['outputId']['value'])
      }
    end

    project['research_outputs'] = child_research_outputs if child_research_outputs.any?
    project
  end

  def run_research_output_query resource_uri
    q = <<-SPARQL.strip_heredoc
        #{common_prefixes}

        SELECT ?output ?outputTitle ?outputDate ?outputLink ?outputId WHERE {

          ?output  dcterms:isPartOf <#{resource_uri}> ;
                    dcterms:title ?outputTitle ;
                    dcterms:date  ?outputDate ;
                    dcterms:identifier ?oId .
          
          BIND(replace(str(?oId), "http://linked-development.org/r4d/output/", '') AS ?outputUriId)
          BIND(replace(str(?outputUriId), "/", '') AS ?outputId)
          BIND(CONCAT("http://r4d.dfid.gov.uk/output/", ?outputId, "/") AS ?outputLink)
        } ORDER BY DESC(?outputDate) #{maybe_per_project_limit} 
    SPARQL

    Tripod::SparqlClient::Query.select(q)
  end

  def maybe_per_project_limit
    @per_project.present? ? "LIMIT #{@per_project}" : ''
  end
end
