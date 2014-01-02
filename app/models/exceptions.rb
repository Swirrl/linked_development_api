class LinkedDevelopmentError < StandardError
end

# Raise this when the document/graph is not one of our allowed types,
# e.g. eldis, r4d or all.
class InvalidDocumentType < LinkedDevelopmentError

end

class DocumentNotFound < LinkedDevelopmentError
end
