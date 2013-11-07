class GetController < ApplicationController
  # Eg http://localhost:3000/openapi/eldis/get/documents/A64559/full
  def documents
    # Figure out what DocumentRepository should be called
    document_repository = DocumentRepository.new
    service = DocumentService.new(document_repository: document_repository)
    @document = service.get(type: "eldis", id: "A64559", detail: "full")

    response.headers["Content-Type"] = "application/json"
    render json: @document
  end
end