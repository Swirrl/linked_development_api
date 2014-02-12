class MetadataURLGenerator
  def initialize(base_uri)
    @base_uri = base_uri
  end

  def document_url(graph, object_id)
    # r4d document identifiers are stored as URL's so convert them to
    # id slugs and re-urlify them.
    if object_id =~ /http:\/\/linked-development.org\/r4d\/output\/([0-9]+)\//
      object_id = Regexp.last_match[1]
    end

    url("/openapi/%s/get/documents/%s/full", graph, object_id)
  end

  def theme_url(graph, object_id)
    url("/openapi/%s/get/themes/%s/full", graph, object_id)
  end

  def country_url(graph, object_id)
    url("/openapi/%s/get/countries/%s/full", graph, object_id)
  end

  def region_url(graph, object_id)
    url("/openapi/%s/get/regions/%s/full", graph, object_id)
  end

  def children_url(graph, object_id)
    url("/openapi/%s/get_children/themes/%s/full", graph, object_id)
  end

  def linked_url(graph, type, object_id)
    @base_uri + ('/%s/%s/%s/' % [graph, type, object_id])
  end
  
  private

  def url(template, graph, object_id)
    @base_uri + (template % [graph, object_id])
  end
end
