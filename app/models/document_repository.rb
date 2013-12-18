require 'rdf/vocab/faogeopol'
require 'rdf/vocab/bibo'

# NOTE:
#  Comments beginning PHP: are copied from the original PHP source

class DocumentRepository
  # There's some Ruby code in this file too, if you scroll down long enough
  GET_DOCUMENT_QUERY_TEMPLATE = <<-SPARQL
    PREFIX dcterms: <http://purl.org/dc/terms/>
    PREFIX bibo: <http://purl.org/ontology/bibo/>
    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX fao: <http://www.fao.org/countryprofiles/geoinfo/geopolitical/resource/>
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
    PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>

    CONSTRUCT {
      ?resource a                 bibo:Article ;
                dcterms:title     ?title ;
                dcterms:abstract  ?abstract ;
                dcterms:creator   ?creator ;
                dcterms:subject   ?subject ;
                bibo:uri          ?uri .

      ?subject rdfs:label         ?subjectTitle ;
               dcterms:identifier ?subjectID .

      # Term relationships
      ?subjectParent  skos:narrower       ?subject ;
                      rdfs:label          ?subjectParentLabel ;
                      dcterms:identifier  ?subjectParentID .

      # Coverage
      ?resource dcterms:coverage    ?coverage .
      ?coverage fao:codeISO2        ?coverageISO ;
                fao:codeUN          ?coverageUN ;
                dcterms:identifier  ?coverageID ;
                rdfs:label          ?coverageTitle.

      ?resource dcterms:language    ?language ;
                dcterms:identifier  ?identifier ;
                rdfs:seeAlso        ?document ;
                dcterms:date        ?date .

      ?resource dcterms:publisher     ?publisher .
      ?publisher  foaf:name           ?publisherName ;
                  dcterms:identifier  ?publisherID ;
                  vcard:hasAddress    ?publisherAddress.

      ?publisherAddress vcard:country ?publisherCountry.
    }

    WHERE {
      VALUES ?resource { <%{uri}> } .

      ?resource a             bibo:Article ;
                dcterms:title ?title .

      OPTIONAL { ?resource dcterms:abstract ?abstract }

      # Creators
      # Handle cases where Creator is directly attached (Eldis), or through a blank node (R4D)
      OPTIONAL {
        {
          ?resource dcterms:creator ?creator .
        } UNION {
          ?resource dcterms:creator/foaf:name ?creator .
        }
        FILTER(isLiteral(?creator))
      }

      # Subjects
      OPTIONAL {
        ?resource dcterms:subject ?subject .
        ?subject rdfs:label ?subjectTitle .
        OPTIONAL {
            ?subject dcterms:identifier ?subjectID .
        }
        OPTIONAL {
          ?subjectParent skos:narrower ?subject
          # Uncomment out the line below to search up the category tree and give all the required steps for building a category path
          # This is expensive, so unless there are use-cases drawing on the category tree from the API we may want to leave it out
          # OPTION (transitive, t_max(4), t_in(?subject), t_out(?subjectParent), t_step("step_no") as ?level)
          .
          ?subjectParent rdfs:label ?subjectParentLabel .
          OPTIONAL { ?subjectParent dcterms:identifier ?subjectParentID . }
        }
      }

      # Coverage
      OPTIONAL {
        ?resource dcterms:coverage ?coverage.
        # Handle for different ways in which coverage may be labelled.
        {
          ?coverage rdfs:label ?coverageTitle
        }
        UNION
        {
          ?coverage fao:nameList ?coverageTitle .
          FILTER(lang(?coverageTitle) = "en" || lang(?coverageTitle) = "")
        }
        OPTIONAL { ?coverage dcterms:identifier ?coverageID }
        OPTIONAL { ?coverage fao:codeISO2 ?coverageISO }
        OPTIONAL { ?coverage fao:codeUN ?coverageUN }
      }

      # Language
      OPTIONAL { ?resource dcterms:language ?language }
      # Identifiers
      OPTIONAL { ?resource dcterms:identifier ?identifier }
      # SeeAlso
      OPTIONAL { ?resource rdfs:seeAlso ?document }
      # Date
      OPTIONAL { ?resource dcterms:date ?date }
      # Publisher Information
      OPTIONAL {
        ?resource dcterms:publisher ?publisher .
        OPTIONAL { ?publisher foaf:name ?publisherName }
      }
      # URI to the document
      OPTIONAL {
        ?resource bibo:uri ?uri
      }
    }
  SPARQL

  def find(details)
    type        = details.fetch(:type)
    document_id = details.fetch(:id)
    detail      = details.fetch(:detail)

    # From the original GetQueryBuilder->createQuery
    # (This appears to be hard-coded to eldis URIs only)

    # Maybe find a better implementation than the original?
    # This seems unnecessarily coupled to the id format and
    # will fail if we have another digits-only id format.
    #
    # PHP: For now we base graph selection on the ID.
    #      ELDIS IDs start with A, whereas R4D are numerical.
    #      Graph will already be respected by the graph query.
    uri =
      if document_id =~ /^A/
        "http://linked-development.org/eldis/output/#{document_id}/"
      else
        "http://linked-development.org/r4d/output/#{document_id}/"
      end

    query   = Tripod::SparqlQuery.new(GET_DOCUMENT_QUERY_TEMPLATE, uri: uri)
    result  = Tripod::SparqlClient::Query.query(query.query, 'text/turtle')
    graph   = RDF::Graph.new.from_ttl(result)
    map_graph_to_document(
      graph,
      detail,
      details.fetch(:metadata_url_generator)
    )
  end
  
  # Once we have a local graph (via the CONSTRUCT) we use this method
  # to query it locally via rdf.rb and assemble a Hash representing
  # the document.
  # 
  # Params:
  #    graph  - the local in-memory rdf graph
  #    detail - "full", "short" or nil.  If nil then we default to "short"
  #    urlgen - generator for metadata URI's
  # 
  # PHP: We currently don't implement category_subject as this data is not captured
  #      in the R4D RDF or in the data import coming from ELDIS
  def map_graph_to_document(graph, detail, metadata_url_generator)
    document = { }

    document_solutions = graph.query(
      RDF::Query.new do
        pattern [:document, RDF.type,           RDF::URI.new("http://purl.org/ontology/bibo/Article")]
        pattern [:document, RDF::DC.title,      :title]
        pattern [:document, RDF::DC.identifier, :_object_id] # :object_id is a reserved method name :-)
        pattern [:document, RDF::DC.date,       :publication_date]
        pattern [:document, RDF::RDFS.seeAlso,  :website_url], optional: true
      end
    )

    document_solution = document_solutions.first

    document_uri        = document_solution.document
    document_object_id  = document_solution._object_id.object
    site                = document_uri.path.split("/")[1] # Original PHP implementation

    # PHP: Custom property not originally in the IDS API
    document["linked_data_uri"] = document_uri.to_s
    document["metadata_url"]    = metadata_url_generator.document_url(site, document_object_id)
    document["object_type"]     = "Document"
    document["object_id"]       = document_object_id
    title                       = document_solution.title.object
    document["title"]           = title

    if detail == "full"
      document["name"]              = document_solution.title.object
      # Note: we also use site later for the metadata URL generation, which may not be correct
      document["site"]              = site

      website_url_uri               = document_solution["website_url"]
      document["website_url"]       = (website_url_uri && website_url_uri.to_s)

      publisher_solutions = graph.query(
        RDF::Query.new do
          pattern [:document,  RDF::DC.publisher, :publisher]
          pattern [:publisher, RDF::FOAF.name,    :publisher_name]
        end
      )
      if publisher_solution = publisher_solutions.first
        document["publisher"]       = publisher_solution.publisher_name.object
      else
        document["publisher"]       = nil
      end

      # Note: as of writing, the dates are being stored as strings, not date(time)s
      publication_date              = document_solution.publication_date.object
      document["publication_date"]  = publication_date.sub("T", " ") # Original PHP implementation
      document["publication_year"]  = Date.parse(publication_date).strftime("%Y")

      # PHP: ToDo - Add more publisher details here (waiting for cache to clear)

      # PHP: ToDo - get license data into system
      document["license_type"]      = "Not Known"

      author_solutions = RDF::Query.execute(graph) do
        pattern [document_uri, RDF::DC.creator, :author]
      end

      document["author"] = author_solutions.map(&:author).map(&:object)

      # We could consider using (as yet unwritten) Theme code to generate this,
      # but the format of a Theme in a Document is different from a Theme itself
      #
      # PHP: EasyRDF is currently not getting all the subjects as it should.
      #      See https://github.com/practicalparticipation/ldapi/issues/4
      document["category_theme_array"]  = { "theme" => [ ] }
      document["category_theme_ids"]    = [ ]
      theme_solutions = graph.query(
        RDF::Query.new do
          pattern [:document, RDF::DC.subject,    :theme]
          pattern [:theme,    RDF::RDFS.label,    :object_name]
          pattern [:theme,    RDF::DC.identifier, :_object_id],   optional: true
        end
      )
      theme_solutions.each do |theme_solution|
        _object_id =
          if identifier_term = theme_solution["_object_id"]
            identifier_term.object
          else
            URI.parse(theme_solution["theme"].to_s).path.split("/").last
          end

        document["category_theme_array"]["theme"] << {
          "archived"      => "false",   # Original PHP was a hard-coded string
          "level"         => "unknown", # Original PHP was a hard-coded string
          "metadata_url"  => metadata_url_generator.theme_url(site, _object_id),
          "object_id"     => _object_id,
          "object_name"   => theme_solution["object_name"].object,
          "object_type"   => "theme"
        }

        document["category_theme_ids"] << _object_id
      end

      coverage_solutions = graph.query(
        RDF::Query.new do
          pattern [:document, RDF::DC.coverage,         :coverage]
          # TODO: find something without a label
          pattern [:coverage, RDF::RDFS.label,          :label] #, optional: true
          pattern [:coverage, RDF::FAOGEOPOL.codeISO2,  :iso_two_letter_code],  optional: true
          pattern [:coverage, RDF::FAOGEOPOL.codeUN,    :un_code],              optional: true
          pattern [:coverage, RDF::DC.identifier,       :identifier],           optional: true
        end
      )

      coverage_solutions.each do |coverage_solution|
        label = coverage_solution.label.object

        if iso_two_letter_code_term = coverage_solution["iso_two_letter_code"]
          iso_two_letter_code = iso_two_letter_code_term.object
          document["country_focus_array"] ||= { "Country" => [ ] }
          document["country_focus"]       ||= [ ]
          document["country_focus_ids"]   ||= [ ]

          document["country_focus_array"]["Country"] << {
            "alternative_name"    => label,
            "iso_two_letter_code" => iso_two_letter_code,
            "metadata_url"        => metadata_url_generator.country_url(site, iso_two_letter_code),
            "object_id"           => iso_two_letter_code,
            "object_name"         => label,
            "object_type"         => "Country"
          }
          document["country_focus"] << label
          document["country_focus_ids"] << iso_two_letter_code
        else
          document["category_region_array"]   ||= { "Region" => [ ] }
          document["category_region_path"]    ||= [ ]
          document["category_region_ids"]     ||= [ ]
          document["category_region_objects"] ||= [ ]

          un_code = coverage_solution["un_code"]
          identifier = coverage_solution["identifier"]
          coverage_id = (un_code && "UN#{un_code.object}") || (identifier && identifier.object) || ""

          document["category_region_array"]["Region"] << {
            "archived"      => "false", # Original PHP was a hard-coded string
            "deleted"       => "0",     # Original PHP was a hard-coded string
            "metadata_url"  => metadata_url_generator.region_url(site, coverage_id),
            "object_id"     => coverage_id,
            "object_name"   => label,
            "object_type"   => "region"
          }
          document["category_region_path"] << label
          document["category_region_ids"] << coverage_id
          document["category_region_objects"] << "#{coverage_id}|region|#{label}"
        end

        document["urls"] = graph.query(
          RDF::Query.new do
            pattern [:document, RDF::Bibo.uri, :url]
          end
        ).map(&:url).map(&:to_s)
      end
    end

    document
  end
end
