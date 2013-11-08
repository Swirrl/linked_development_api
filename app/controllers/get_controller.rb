class GetController < ApplicationController
  # Eg http://localhost:3000/openapi/eldis/get/documents/A64559/full
  def documents
    service = DocumentService.build
    @document = service.get(type: "eldis", id: "A64559", detail: params[:detail])

    response.headers["Content-Type"] = "application/json"
    render json: @document
  end
end