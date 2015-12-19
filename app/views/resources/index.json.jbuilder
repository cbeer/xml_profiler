json.array!(@resources) do |resource|
  json.extract! resource, :id, :file
  json.url resource_url(resource, format: :json)
end
