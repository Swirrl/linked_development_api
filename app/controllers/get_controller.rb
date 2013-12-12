class GetController < ApplicationController
  # Eg http://localhost:3000/openapi/eldis/get/documents/A64559/full
  def documents
    service = DocumentService.build
    @document = service.get(type: params[:graph], id: params[:id], detail: params[:detail])

    response.headers["Content-Type"] = "application/json"
    render json: @document
  end
end
