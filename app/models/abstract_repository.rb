class AbstractRepository
  class << self 
    def eldis_graph_uri
      "http://linked-development.org/graph/eldis"
    end
    
    def r4d_graph_uri
      "http://linked-development.org/graph/r4d"
    end
    
    def common_prefixes
      <<-PREFIXES
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX bibo: <http://purl.org/ontology/bibo/>
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX fao: <http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>
      PREFIXES
    end
  end

  def build_base_query limit=nil
    query = construct << where_clause
    query
  end

  def maybe_limit_clause
    @limit.present? ? " LIMIT #{@limit}" : ''
  end

  def where_clause 
    if @type == 'eldis'
      "WHERE { #{build_eldis_base_query} }"
    elsif @type == 'r4d'
      "WHERE { #{build_r4d_base_query} }"
    else # all
      "WHERE { { #{build_r4d_base_query} } UNION { #{build_eldis_base_query} } }"
    end
  end

end
