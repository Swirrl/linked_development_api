module CountByTheme
  include Countable

  def count type, opts
    do_count type, opts do |r| 
      obj_id = r['countableId']['value']
      obj_id.gsub!('/', '')
      meta_url = obj_id.empty? ? '' : @metadata_url_generator.theme_url(@type, obj_id)
      level = obj_id.empty? ? '' : 'NPIS' 
      {
       'metadata_url' => meta_url,
       'object_id' => obj_id,
       'count' => Integer(r['count']['value']),
       'object_type' => 'theme',
       'level' => level,
       'object_name' => r['countableName']['value']
      }
    end
  end

  private

  def countable_fragment
    <<-SPARQL.strip_heredoc
      ?document a bibo:Article ;
                a ?articleType .
 
      ?document dcterms:subject ?countable .
      ?countable a skos:Concept .
    SPARQL
  end
  
  def primary_count_clause
    count_documents_fragment = <<-SPARQL.strip_heredoc
      #{countable_fragment}
      #{optional_countable_clauses}
    SPARQL

    filter_clause = <<-SPARQL.strip_heredoc
                       ?document dcterms:subject ?countable . ?countable a skos:Concept .
                    SPARQL

    unionise(unlinked_documents_subquery(filter_clause), apply_graph_type_restriction(count_documents_fragment))
  end
  
  def optional_countable_clauses
    <<-SPARQL.strip_heredoc
      OPTIONAL { ?countable rdfs:label ?countableName }
      OPTIONAL { ?countable skos:prefLabel ?countableName }
      OPTIONAL { ?countable skos:preLabel ?countableName }

      BIND(replace(str(?countable), "(http://aims.fao.org/aos/agrovoc/|http://dbpedia.org/resource/|http://linked-development.org/eldis/themes/)", '') AS ?countableId)
    SPARQL
  end
end
