require 'exceptions'
require_relative './modules/countable/count_by_country'

class CountryRepository < AbstractRepository

  include SparqlHelpers
  include CountByCountry
  include Pageable
  include Getable
  include Totalable

  private 

  def construct 
    <<-CONSTRUCT.strip_heredoc
      CONSTRUCT {
        #{var_or_iriref(@resource_uri)} a fao:territory ;
                 rdfs:label ?countrylabel ;
                 dcterms:identifier ?objectId ;
                 fao:codeISO2 ?countryCode ;
                 <#{local_uri('graphName')}> ?graph .
      }
    CONSTRUCT
  end

  def where_clause
    <<-SPARQL
      {
            SELECT DISTINCT #{uri_or_as(@resource_uri)} ?graph ?countryCode ?countrylabel ?objectId WHERE {
                #{primary_where_clause}
            } #{maybe_limit_clause} #{maybe_offset_clause}
      }
    SPARQL
  end

  def primary_where_clause
    primary_clause = case @type
                       when 'eldis' ; eldis_subquery
                       when 'r4d' ; r4d_subquery
                       else unionise(eldis_subquery, r4d_subquery) # all
                     end
    primary_clause
  end

  def eldis_subquery
    <<-SPARQL.strip_heredoc
          GRAPH <http://linked-development.org/graph/eldis> {
            VALUES ?graph { "eldis" }
            ?article a bibo:Article ;
               dcterms:coverage #{var_or_iriref(@resource_uri)} .
            
            #{var_or_iriref(@resource_uri)} fao:codeISO2 ?countryCode ;
                     rdfs:label ?countrylabel ;
                     dcterms:identifier ?objectId .
          }
    SPARQL
  end
  
  def r4d_subquery
    <<-SPARQL.strip_heredoc
           GRAPH <http://linked-development.org/graph/r4d> {
             VALUES ?graph { "r4d" }
             ?article a bibo:Article ;
               dcterms:coverage #{var_or_iriref(@resource_uri)} .
           
             #{var_or_iriref(@resource_uri)} fao:nameList ?countrylabel .
             FILTER(lang(?countrylabel) = 'en')
      
             #{var_or_iriref(@resource_uri)} fao:codeISO2 ?countryCode .
           
             BIND(replace(str(#{var_or_iriref(@resource_uri)}), "http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/", '') AS ?objectId) .
           }
    SPARQL
  end

  def get_solutions_from_graph graph
    country_res = @resource_uri ? RDF::URI.new(@resource_uri) : :country_uri
    
    country_code_uri = RDF::URI.new("http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/codeISO2")
    
    graph_type = RDF::URI.new(local_uri('graphName'))

    # don't offset here as this is just a subset of the results from the server
    country_solutions = RDF::Query.execute(graph) do |q| 
      q.pattern [country_res, RDF::RDFS.label,    :label]
      q.pattern [country_res, RDF::DC.identifier, :_object_id]
      q.pattern [country_res, country_code_uri, :country_code]
      q.pattern [country_res, graph_type, :graph_name]

    end.limit(@limit)

    country_solutions
  end

  def process_each_result graph, current_country
    country = { }

    parent_uri = @resource_uri ? RDF::URI.new(@resource_uri) : current_country.country_uri

    country['title'] = current_country.label.value
    country['object_id'] = current_country._object_id.value
    country['iso_two_letter_code'] = current_country.country_code.value
    country['object_type'] = 'country' # NOTE this was upper case in the PHP api... Changed it to lower case for consistency.
    country['metadata_url'] = @metadata_url_generator.country_url(current_country.graph_name.value, current_country._object_id.value)
    country['linked_data_uri'] = parent_uri.to_s
    
    country
  end

end
