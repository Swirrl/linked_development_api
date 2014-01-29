module CountByRegion
  include Countable
  
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

end
