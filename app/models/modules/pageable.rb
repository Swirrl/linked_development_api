module Pageable

  protected

  def parse_limit opts
    (opts == nil || opts[:limit] == nil) ? 10 : Integer(opts[:limit])
  end

  def parse_offset opts
    (opts == nil || opts[:offset] == nil) ? 0 : Integer(opts[:offset])
  end
  
  def maybe_limit_clause
    @limit.present? ? " LIMIT #{@limit}" : ''
  end

  def maybe_offset_clause
    @limit.present? && @offset.present? ? " OFFSET #{@offset}" : ''
  end
end
  
