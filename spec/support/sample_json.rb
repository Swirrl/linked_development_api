module SampleJson

  def sample_json(filename)
    JSON.parse(File.read(File.join(File.dirname(__FILE__), '..' , 'application', 'samples', filename)))
  end

  # SORT JSON objects to help aid comparisons in tests.
  def sort_hash unsorted_hash
    sorted_hash = Hash.new

    unsorted_hash.keys.sort.reverse.each do |k| 
      v = unsorted_hash[k]
      v = sort_hash(v) if v.class == Hash
      
      if v.class == Array
        v.each_with_index do |o, i| 
          if o.class == Hash
            v[i] = sort_hash o
          end
        end
      end
      
      sorted_hash[k] = v
    end
    
    sorted_hash
  end

end
