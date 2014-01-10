require 'exceptions'

class ThemeService < AbstractService
  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(theme_repository: ThemeRepository.new)
    end
  end

  def initialize(dependencies = { })
    @repository = dependencies.fetch(:theme_repository)
  end

  def get details
    set_instance_vars details
    validate

    merge_uri_with! details

    result = if @type == 'eldis' && is_eldis_id?(@resource_id)
               @repository.get_eldis details
             elsif @type == 'r4d' && (is_dbpedia_id?(@resource_id) || is_agrovoc_id?(@resource_id))
               @repository.get_r4d details
             elsif @type == 'all'
                 if is_dbpedia_id?(@resource_id) || is_agrovoc_id?(@resource_id)
                   @repository.get_r4d details 
                 elsif is_eldis_id?(@resource_id)
                   @repository.get_eldis details 
                 else
                   raise LinkedDevelopmentError, "Unexpected :id format."
                 end
             else
               raise LinkedDevelopmentError, "Invalid :id format (#{@resource_id}) with graph @type #{@type}"
             end

    wrap_result result
  end

  def get_all details, opts
    set_instance_vars details, opts
    validate

    results = @repository.get_all details, opts

    base_url = Rails.application.routes.url_helpers.get_all_themes_url(@type, {:host => opts[:host], :format => :json, :detail => @detail})
    wrap_results results, base_url
  end

  private

  # Generate a resource URI for the theme, note this is different from a 'metadata_url'
  def convert_id_to_uri res_id
    if is_eldis_id? res_id
      "http://linked-development.org/eldis/themes/#{res_id}/"
    elsif is_agrovoc_id? res_id
      "http://aims.fao.org/aos/agrovoc/#{res_id}"
    else is_dbpedia_id? res_id
      "http://dbpedia.org/resource/#{res_id}"
    end
  end

  def is_eldis_id? identifier
    identifier =~ /^C\d{1,}$/
  end

  def is_agrovoc_id? identifier
    identifier =~ /^c_\d{1,}$/
  end

  def is_dbpedia_id? identifier
    !is_eldis_id?(identifier) && !is_agrovoc_id?(identifier)
  end
end
