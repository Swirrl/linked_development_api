require 'rdf/vocab/faogeopol'
require 'rdf/vocab/bibo'

# NOTE:
#  Comments beginning PHP: are copied from the original PHP source

class DocumentRepository < AbstractRepository

  include SparqlHelpers
  include Countable
  include Pageable
  include Getable
  include Totalable
  
  private

  def primary_where_clause
    base_query_pattern = <<-SPARQL.strip_heredoc
          ?resource a bibo:Article ;
            dcterms:title ?title .
    SPARQL
    
    apply_graph_type_restriction(base_query_pattern)
  end
 
  def get_solutions_from_graph graph
    # don't offset here as this is just a subset of the results from
    # the server
    document_solutions = RDF::Query.execute(graph) do |q|
      q.pattern [:document, RDF.type,           RDF::URI.new("http://purl.org/ontology/bibo/Article")]
      q.pattern [:document, RDF::DC.title,      :title]
      q.pattern [:document, RDF::DC.identifier, :_object_id] # :object_id is a reserved method name :-)
      q.pattern [:document, RDF::DC.date,       :publication_date]
      q.pattern [:document, RDF::RDFS.seeAlso,  :website_url], optional: true
    end.limit(@limit)

    document_solutions
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
  def process_each_result graph, document_solution
    document = { }

    document_uri        = document_solution.document
    document_object_id  = document_solution._object_id.object
    site                = document_uri.path.split("/")[1] # Original PHP implementation

    # PHP: Custom property not originally in the IDS API
    document["linked_data_uri"] = document_uri.to_s
    document["metadata_url"]    = @metadata_url_generator.document_url(site, document_object_id)
    document["object_type"]     = "Document"
    document["object_id"]       = document_object_id
    title                       = document_solution.title.object
    document["title"]           = title

    if @detail == "full"
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
          "metadata_url"  => @metadata_url_generator.theme_url(site, _object_id),
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
            "metadata_url"        => @metadata_url_generator.country_url(site, iso_two_letter_code),
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
            "metadata_url"  => @metadata_url_generator.region_url(site, coverage_id),
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

  def construct
    <<-ENDCONSTRUCT
    CONSTRUCT {
      #{var_or_iriref(@resource_uri)} a                 bibo:Article ;
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
      #{var_or_iriref(@resource_uri)} dcterms:coverage    ?coverage .
      ?coverage fao:codeISO2        ?coverageISO ;
                fao:codeUN          ?coverageUN ;
                dcterms:identifier  ?coverageID ;
                rdfs:label          ?coverageTitle.

      #{var_or_iriref(@resource_uri)} dcterms:language    ?language ;
                dcterms:identifier  ?identifier ;
                rdfs:seeAlso        ?document ;
                dcterms:date        ?date .

      #{var_or_iriref(@resource_uri)} dcterms:publisher     ?publisher .
      ?publisher  foaf:name           ?publisherName ;
                  dcterms:identifier  ?publisherID ;
                  vcard:hasAddress    ?publisherAddress.

      ?publisherAddress vcard:country ?publisherCountry.
    }
ENDCONSTRUCT
  end

  # the primary article selection query.  Everything else is optional.
  def primary_selection_query
    graph_pattern = <<-GP.strip_heredoc
      #{var_or_iriref(@resource_uri)} a bibo:Article ;
                dcterms:title ?title .
GP
    
    <<-PRIMARY.strip_heredoc
          SELECT DISTINCT * WHERE {
            #{apply_graph_type_restriction(graph_pattern)}
          }
PRIMARY
  end

  def where_clause
    <<-SPARQL.strip_heredoc
    WHERE {
      {    
          #{primary_selection_query}  
          #{maybe_limit_clause} #{maybe_offset_clause}
      }

      OPTIONAL { #{var_or_iriref(@resource_uri)} dcterms:abstract ?abstract }

      # Creators
      # Handle cases where Creator is directly attached (Eldis), or through a blank node (R4D)
      OPTIONAL {
        {
          #{var_or_iriref(@resource_uri)} dcterms:creator ?creator .
        } UNION {
          #{var_or_iriref(@resource_uri)} dcterms:creator/foaf:name ?creator .
        }
        FILTER(isLiteral(?creator))
      }

      # Subjects
      OPTIONAL {
        #{var_or_iriref(@resource_uri)} dcterms:subject ?subject .
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
        #{var_or_iriref(@resource_uri)} dcterms:coverage ?coverage.
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
      OPTIONAL { #{var_or_iriref(@resource_uri)} dcterms:language ?language }
      # Identifiers
      OPTIONAL { #{var_or_iriref(@resource_uri)} dcterms:identifier ?identifier }
      # SeeAlso
      OPTIONAL { #{var_or_iriref(@resource_uri)} rdfs:seeAlso ?document }
      # Date
      OPTIONAL { #{var_or_iriref(@resource_uri)} dcterms:date ?date }
      # Publisher Information
      OPTIONAL {
        #{var_or_iriref(@resource_uri)} dcterms:publisher ?publisher .
        OPTIONAL { ?publisher foaf:name ?publisherName }
      }
      # URI to the document
      OPTIONAL {
        #{var_or_iriref(@resource_uri)} bibo:uri ?uri
      }
    }
  SPARQL
  end
end
