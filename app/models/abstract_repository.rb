class AbstractRepository

  def initialize
    @metadata_url_generator = MetadataURLGenerator.new("http://linked-development.org")
  end

end
