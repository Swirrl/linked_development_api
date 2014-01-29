module Totalable

  # expects a get_all query to have been run first.
  def total_results_of_last_query 
    raise StandardError, 'A get_all query must have been run before calling this method.' if @type == nil
    result = Tripod::SparqlClient::Query.select totalise_query(primary_where_clause)
    result[0]['total']['value'].to_i
  end

  protected
  
  def totalise_query query_clauses
    raise StandardError, 'Subclasses should implement this #totalise_query method to support #total_results'
  end

  def totalise_query primary_subquery, count_var="?resource"
    <<-SPARQL.strip_heredoc
    #{common_prefixes}

    SELECT (COUNT(DISTINCT #{count_var}) AS ?total) WHERE { 
       {
           #{primary_subquery}
       }
    }
    SPARQL
  end
  
  # Objects that want to reuse totalise_query need to implement this
  # method.  And ensure that ?resource is a SPARQL variable, as this
  # is what we count. This method should avoid using limit/offset, as
  # it needs to return the number of available results.
  def primary_where_clause
    raise StandardError, 'To use #totalise_query, you must implement #primary_where_clause'
  end
  
end
