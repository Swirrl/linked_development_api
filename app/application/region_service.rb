require 'exceptions'

class RegionService < AbstractService
  class << self
    # Convenience factory method to construct a new DocumentService
    # with the usual dependencies
    def build
      new(repository: RegionRepository.new)
    end
  end

  def get details
    set_instance_vars details
    validate
    merge_uri_with! details

    if RegionService.is_eldis_id?(@resource_id)
      result = @repository.get_eldis(details)
    else
      details.merge!(type: 'r4d')
      result = @repository.get_r4d(details)
    end

    wrap_result(result)
  end

  def count details, opts
    set_instance_vars details, opts
    base_url = Rails.application.routes.url_helpers.count_regions_url(@type, {:host => opts[:host], :format => @format})
    results = super(details, opts)
    wrap_count_results results, base_url
  end

  def get_all details, opts
    results = do_get_all details, opts

    base_url = Rails.application.routes.url_helpers.get_all_regions_url(@type, {:host => opts[:host], :format => @format, :detail => @detail})

    wrap_results(results, base_url)
  end

  private

  def self.is_eldis_id? region_id
    region_id =~ /C[0-9]+/
  end

  def convert_id_to_uri region_id
    RegionService.is_eldis_id?(region_id) ? "http://linked-development.org/eldis/geography/#{region_id}/" : nil
  end


end
