class AbstractRepository

  def initialize
    @search_parameters = {}
    @metadata_url_generator = MetadataURLGenerator.new("http://linked-development.org")
  end

end
