require 'cgi'
require 'rest_client'
require 'json'

endpoint = "http://linked-development.org/sparql?query="
graphs = ["http://linked-development.org/eldis/","http://linked-development.org/r4d/"]
output_files = ["eldis.nt","r4d.nt"]
chunksize = 50000

for i in 0..1
  graph = graphs[i]
  output = output_files[i]
  
  f = File.new(output,'w')
  
  puts graph
  puts output
  
  # find out how many triples
  countquery = "SELECT (COUNT(*) as ?c) WHERE {GRAPH <#{graph}> {?s ?p ?o}}"
  query_url = endpoint + CGI::escape(countquery)
  response = RestClient.get query_url, :accept => "application/sparql-results+json"
  result = JSON.parse(response.body)
  count = result["results"]["bindings"][0]["c"]["value"].to_i
  puts "count is #{count.to_s}"
  numchunks = (count/chunksize) + 1
  puts "number of chunks: #{numchunks.to_i}"

  for i in 0..(numchunks-1)
    offset = i*chunksize
    
    puts "starting chunk #{i}"
    dataquery = "CONSTRUCT {?s ?p ?o} WHERE {GRAPH <#{graph}> {?s ?p ?o}} LIMIT #{chunksize.to_s} OFFSET #{offset.to_s}"
    query_url = endpoint + CGI::escape(dataquery)
    response = RestClient.get query_url, :accept => "text/plain"

    f << response.body

    
  end
  f.close
  
end