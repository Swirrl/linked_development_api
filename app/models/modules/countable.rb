module Countable
  def count type, opts
    raise StandardError, 'Subclasses should override this method. Where appropriate.'
  end

  def total_results_of_count_query
    raise StandardError, 'A count query must have been run before calling this method.' if @type == nil

    q_string = totalise_query(apply_graph_type_restriction(countable_fragment), "?countable")

    Rails.logger.info q_string

    result = Tripod::SparqlClient::Query.select q_string
    result[0]['total']['value'].to_i
  end

  private
  
  def do_count type, opts, &block
    @type = type
    @limit = parse_limit opts
    @offset = parse_offset opts
    
    results  = Tripod::SparqlClient::Query.select(count_query_string)

    results.map do |r|
      yield r
    end
  end

  def count_query_string
    q = <<-SPARQL.strip_heredoc
    #{common_prefixes}

    SELECT ?countable ?countableId ?countableName (COUNT(DISTINCT ?document) AS ?count) WHERE {
       #{primary_count_clause}
    } GROUP BY ?countable ?countableId ?countableName #{maybe_limit_clause} #{maybe_offset_clause}
    SPARQL

    Rails.logger.info q
    q
  end

  # This subquery supports counting documents that don't contain a specific triple pattern
  def unlinked_documents_subquery not_triple_pattern
    query_pattern = <<-SPARQL.strip_heredoc
        ?document a bibo:Article ;
                  a ?articleType .
      
        FILTER NOT EXISTS {
          #{not_triple_pattern}
        }
    SPARQL

    query_pattern = @type == 'all' ? unionise(graphise('r4d', query_pattern), graphise('eldis', query_pattern))
                                   : {'r4d' => query_pattern, 'eldis' => query_pattern}[@type]
    
    <<-SPARQL.strip_heredoc
      SELECT ?document ("" AS ?countable) ("" AS ?countableId)  ("" AS ?countableName) WHERE {
         #{query_pattern}
      }
    SPARQL
  end
end
