# Helpers for building SPARQL query strings
module SparqlHelpers

  # Use this for coining localised graph uri's.  A bit of a hack, but
  # it lets us generate URI's for construct graphs that only have
  # meaning within this app.
  def local_uri slug
    "http://linked-development.org/dev/#{slug}"
  end
  
  def common_prefixes
      <<-PREFIXES.strip_heredoc
        PREFIX dcterms: <http://purl.org/dc/terms/>
        PREFIX bibo: <http://purl.org/ontology/bibo/>
        PREFIX foaf: <http://xmlns.com/foaf/0.1/>
        PREFIX fao: <http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
        PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>
        PREFIX linkeddev: <#{local_uri('')}>
        PREFIX dbpo: <http://dbpedia.org/ontology/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      PREFIXES
  end

  # Generates a string that conforms to a VarOrIRIref in the SPARQL
  # grammar.  If the supplied argument is nil then we return a string
  # of '?resource' othewise we return a SPARQL IRIRef (i.e. a '<URI>'
  # string.)
  def var_or_iriref maybe_uri, var='?resource'
    if maybe_uri
      "<#{maybe_uri}>"
    else
      var
    end
  end

  # Generates a string that conforms to a VarOrIRIref in the SPARQL
  # grammar.  If the supplied argument is nil then we return a string
  # of '?resource' othewise we return a SPARQL IRIRef (i.e. a '<URI>'
  # string.)
  def var_or_literal maybe_literal, var='?resource'
    if maybe_literal
      "\"#{maybe_literal}\""
    else
      var
    end
  end

  def literal_or_as maybe_literal, var='?resource'
    if maybe_literal 
      "(\"#{maybe_literal}\" AS #{var})"
    else
      var
    end    
  end
  
  def uri_or_as maybe_uri, var='?resource'
    if maybe_uri 
      "(<#{maybe_uri}> AS #{var})"
    else
      var
    end
  end

  # Builds a union query out of the supplied sub query strings
  def unionise *sub_queries
    sub_queries_with_parens = sub_queries.map do |i| 
      "{ #{i} }" 
    end

    sub_queries_with_parens.join(' UNION ')
  end
  
  def graphise graph_slug, query
    <<-SPARQL.strip_heredoc
    GRAPH <http://linked-development.org/graph/#{graph_slug}> {  
      #{query} 
    }
    SPARQL
  end
  
  # wrap in a WHERE clause
  def whereise query_str
    <<-SPARQL.strip_heredoc
    WHERE {
       #{query_str}
    }
    SPARQL
  end
  
  def apply_graph_type_restriction query_str
    @type == 'all' ? unionise(graphise('eldis', query_str), 
                              graphise('r4d', query_str)) 
                   : graphise(@type, query_str)
  end
end
