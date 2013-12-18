module SampleJson

  def sample_json(filename)
    JSON.parse(File.read(File.join(File.dirname(__FILE__), '..' , 'application', 'samples', filename)))
  end

end
