require 'exceptions'

class RegionRepository < AbstractRepository

  include SparqlHelpers
  include Countable
  include Pageable
  include Getable
  include Totalable

  def count details, opts
    do_count details, opts do |r|
      obj_id = r['countableId']['value']
      obj_id.gsub!('/', '')
      meta_url = obj_id.empty? ? '' : @metadata_url_generator.region_url(@type, obj_id)
      {
       'metadata_url' => meta_url,
       'object_id' => obj_id,
       'count' => Integer(r['count']['value']),
       'object_type' => 'region',
       'object_name' => r['countableName']['value']
      }
    end
  end
  
  def get_one details
    raise StandardError, 'This class does not support this method use #get_eldis and #get_r4d instead.'
  end

  def get_eldis details
    set_common_details details, raise_error_on_nil_resource_uri: true
    @limit = 1
    @type = 'eldis'

    query_string = build_base_query
    Rails.logger.debug query_string

    result  = Tripod::SparqlClient::Query.query(query_string, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    process_one_or_many_results(graph).first
  end

  def get_r4d details
    # r4d works off object_id because the URI is not conveniently
    # slugged for us.

    set_common_details details, raise_error_on_nil_resource_uri: false
    @type = 'r4d'
    @limit = 1

    query_string = build_base_query
    Rails.logger.debug query_string

    result  = Tripod::SparqlClient::Query.query(query_string, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)

    process_one_or_many_results(graph).first
  end

  private
  
  def primary_count_clause
    eldis_fragment = <<-SPARQL.strip_heredoc
      ?countable a fao:geographical_region ;
                 skos:inScheme <http://linked-development.org/eldis/geography/> ;
                 rdfs:label ?countableName ;
                 dcterms:identifier ?countableId .
    SPARQL

    r4d_fragment = <<-SPARQL.strip_heredoc
            ?countable a fao:geographical_region ;
                       fao:codeUN ?countableId ; 
                       fao:nameList ?countableName .
      
      FILTER(lang(?countableName) = 'en')
    SPARQL

    subquery = @type == 'all' ? unionise(graphise('r4d', r4d_fragment), graphise('eldis', eldis_fragment))
                              : {'r4d' => r4d_fragment, 'eldis' => eldis_fragment}[@type]
    
    count_documents_fragment = <<-SPARQL.strip_heredoc
      ?document a bibo:Article ;
                a ?articleType .
  
      ?document dcterms:coverage ?countable .
      #{subquery}
    SPARQL

    unionise(apply_graph_type_restriction(count_documents_fragment), unlinked_documents_subquery('?document dcterms:coverage ?countable .'))
  end

  alias :countable_fragment :primary_count_clause

  def construct 
    <<-CONSTRUCT.strip_heredoc
      CONSTRUCT {
          ?resource rdfs:label ?regionLabel ; 
                    dcterms:identifier ?objectId ;
                    <#{local_uri('graphName')}> ?graph .
      }
    CONSTRUCT
  end

  def where_clause clauses=nil
    <<-SPARQL
      {
            SELECT DISTINCT #{uri_or_as(@resource_uri)} ?graph ?regionLabel ?objectId WHERE {
                #{primary_where_clause}
            } #{maybe_limit_clause} #{maybe_offset_clause}
      }
    SPARQL
  end

  def primary_where_clause
    primary_clause = case @type
                       when 'eldis' ; eldis_subquery
                       when 'r4d' ; r4d_subquery
                       when 'all' ; unionise(eldis_subquery, r4d_subquery)
                     end
    primary_clause
  end

  def eldis_subquery
    <<-SPARQL.strip_heredoc
      GRAPH <http://linked-development.org/graph/eldis> {
        VALUES ?graph { "eldis" }
        #{var_or_iriref(@resource_uri)} a fao:geographical_region ;
                  skos:inScheme <http://linked-development.org/eldis/geography/> ;
                  rdfs:label ?regionLabel ;
                  dcterms:identifier ?objectId .
      }
    SPARQL
  end

  def r4d_subquery
    object_id = @resource_id.present? ? "VALUES ?objectId { \"#{@resource_id}\"^^xsd:string }" 
                                      : ''

    <<-SPARQL.strip_heredoc
    GRAPH <http://linked-development.org/graph/r4d> {
      VALUES ?graph { "r4d" }
             #{object_id}
             ?resource a fao:geographical_region ;
                       fao:codeUN ?objectId ; 
                       fao:nameList ?regionLabel .
      
      FILTER(lang(?regionLabel) = 'en')
    }
    SPARQL
  end

  def get_solutions_from_graph graph
    region_res = @resource_uri ? RDF::URI.new(@resource_uri) : :region_uri
    
    graph_type_uri = RDF::URI.new(local_uri('graphName'))

    # don't offset here as this is just a subset of the results from the server
    region_solutions = RDF::Query.execute(graph) do |q| 
      q.pattern [region_res, RDF::RDFS.label,    :label]
      q.pattern [region_res, RDF::DC.identifier, :_object_id]
      q.pattern [region_res, graph_type_uri, :graph_name]
    end.limit(@limit)

    region_solutions
  end

  def process_each_result graph, current_region
    region = { }

    parent_uri = @resource_uri ? RDF::URI.new(@resource_uri) : current_region.region_uri

    region['title'] = current_region.label.value
    region['object_id'] = current_region._object_id.value
    region['object_type'] = 'region'
    region['metadata_url'] = @metadata_url_generator.region_url(current_region.graph_name.value, current_region._object_id.value)
    region['linked_data_uri'] = parent_uri.to_s
    
    region
  end
end
