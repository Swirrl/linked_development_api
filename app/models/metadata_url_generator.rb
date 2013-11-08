class MetadataURLGenerator
  def initialize(base_uri)
    @base_uri = base_uri
  end

  def document_url(graph, object_id)
    url("/openapi/%s/get/documents/%s/full", graph, object_id)
  end

  def theme_url(graph, object_id)
    url("/openapi/%s/get/themes/%s", graph, object_id)
  end

  def country_url(graph, object_id)
    url("/openapi/%s/get/countries/%s/full", graph, object_id)
  end

  def region_url(graph, object_id)
    url("/openapi/%s/get/regions/%s/full", graph, object_id)
  end

  private

  def url(template, graph, object_id)
    @base_uri + (template % [graph, object_id])
  end
end