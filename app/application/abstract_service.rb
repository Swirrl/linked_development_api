class AbstractService

  attr_reader :valid_graphs
  
  def initialize(dependencies = { })
    @repository = dependencies.fetch(:repository)
    @valid_graphs = %w[all eldis r4d]
  end

  def get details
    set_instance_vars details
    validate 
    merge_uri_with! details
    
    result = @repository.get_one(details)

    wrap_result(result)
  end

  def do_get_all details, opts
    set_instance_vars details, opts
    validate 
    @repository.get_all details, opts
  end

  def count details, opts
    raise InvalidDocumentType, "Graph #{@type} is not supported for this object type.  Valid graphs are: #{@valid_graphs.join(', ')}." unless graph_valid?
    @repository.count @type, opts
  end
  
  protected

  def set_instance_vars details, opts=nil
    @type = details.fetch(:type)
    @detail = details[:detail]
    @resource_id = details[:id] # allow nil

    set_pagination_parameters opts
  end

  def set_pagination_parameters opts
    if opts.present?
      @offset = (opts[:offset] || 0).to_i
      @limit = (opts[:limit] || 10).to_i
    end
  end
  
  def graph_valid? 
    valid_graphs.include?(@type)
  end

  def detail_valid?
    ['full', 'short', nil].include? @detail
  end

  def wrap_result result
    raise DocumentNotFound, "No resource found with id #{@resource_id} not found" if result.nil?
    {
      "results" => [result]
    }
  end

  # Note to use this Subclasses must implement #convert_id_to_uri.
  def merge_uri_with! details 
    resource_uri = convert_id_to_uri(@resource_id)
    details.merge! :resource_uri => resource_uri
  end
  
  def convert_id_to_uri id
    raise StandardError, 'Override #convert_id_to_uri in subclass to use #merge_uri_with'
  end

  def wrap_results results, base_url
    number_of_matched_results = @repository.total_results_of_last_query
    wrap_count_common(results, number_of_matched_results, base_url)
  end

  def wrap_count_results results, base_url
    number_of_matched_results = @repository.total_results_of_count_query
    Rails.logger.debug "num matched: #{number_of_matched_results}"
    wrap_count_common(results, number_of_matched_results, base_url)
  end

  # common wrapping JSON structure of openapi queries.  Shared by
  # count and get_all queries.
  def wrap_count_common results, number_of_matched_results, base_url
    results = [] if results.nil?
    {
      'results' => results,
      'metadata' => metadata(base_url, number_of_matched_results)
    }
  end
    
  def metadata base_url, number_of_matched_results
    offset = @offset.present? ? Integer(@offset) : 0
    limit = @limit.present? ? Integer(@limit) : 10

    params = {:num_results => limit}

    ret = {
     "num_results"   => number_of_matched_results,
     "start_offset"  => offset
    }

    next_offset = offset + limit
    prev_offset = offset - limit

    Rails.logger.debug("next_offset is #{next_offset} current offset: #{offset} limit: #{limit} previous offset is: #{prev_offset}")
    
    if next_offset < number_of_matched_results
      next_params = params.merge(:start_offset => next_offset).to_query
      ret['next_page'] = add_params_to_uri(base_url, next_params)
    end

    if prev_offset >= 0
      prev_params = params.merge(:start_offset => prev_offset).to_query
      ret['prev_page'] = add_params_to_uri(base_url, prev_params)
    end
    
    ret
  end

  def validate
    validate_detail
    validate
  end

  def validate_graph
    raise InvalidDocumentType, "Graph #{@type} is not supported for this object type.  Valid graphs are: #{@valid_graphs.join(', ')}." unless graph_valid?    
  end
  
  def validate_detail
    raise LinkedDevelopmentError, 'Detail must be either full, short or unspecified (in which case it defaults to short).' unless detail_valid?
  end
  
  private

  # Append parameters to a URL string.  Appends parameters properly in
  # the presence of a '?'
  def add_params_to_uri uri, params
    if uri.include? '?'
      "#{uri}&#{params}"
    else
      "#{uri}?#{params}"
    end
  end
end
