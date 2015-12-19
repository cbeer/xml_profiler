class Resource < ActiveRecord::Base
  mount_uploader :file, ResourceUploader

  after_save do
    reindex
  end

  def reindex
    Blacklight.default_index.connection.add to_solr
  end

  def to_solr
    { id: self.to_global_id }.merge XmlProfiler::Indexer.new(file.file.to_file).to_hash
  end
end
