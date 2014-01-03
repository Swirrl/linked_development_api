class AbstractService
  protected

  def parse_limit i
    i == nil ? 10 : Integer(i)
  end

  def graph_valid? graph
    %w[eldis r4d all].include?(graph)
  end

  def detail_valid? detail
  ['full', 'short', nil].include? detail
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
