module XmlProfiler
  ##
  # Transforming an XML document into a Solr hash
  class Indexer
    attr_reader :doc

    def initialize(doc)
      if doc.is_a?(String) || doc.is_a?(IO)
        @doc = Nokogiri::XML(doc)
      else
        @doc = doc
      end

      @path_cache = {}
    end

    def to_hash
      doc.remove_namespaces!
      doc.xpath('//*').each_with_object({ document_tesim: doc.to_s }.with_indifferent_access) do |el, h|
        fls = xml_el_to_solr_fields(el)

        fls.each do |fl|
          add_count_hash(h, fl, el)
          add_children_hash(h, fl, el)
          add_value_hash(h, fl, el)
          add_attr_hash(h, fl, el)
        end
      end.merge(doc_info)
    end

    private

    def doc_info
      {
        doc_root_ssim: doc.root.path
      }
    end

    def add_count_hash(h, fl, _el)
      h["count(#{fl})_isim"] ||= 0
      h["count(#{fl})_isim"] += 1
    end

    def add_children_hash(h, fl, el)
      h["#{fl}/*_ssim"] ||= []
      h["#{fl}/*_ssim"] += el.children.reject { |x| x.name == 'text' && x.text.blank? }.map(&:name).uniq
      h["#{fl}/*_ssim"] += el.attributes.keys.map { |x| "@#{x}" }
    end

    def add_value_hash(h, fl, el)
      values = el.children.select(&:text?).reject(&:blank?).map(&:text)

      h["#{fl}/text()_ssim"] ||= []
      h["#{fl}/text()_ssim"] += values.map { |v| normalize_text(el, v) }

      h["#{fl}/text()_tesim"] ||= []
      h["#{fl}/text()_tesim"] += values.map { |v| normalize_text(el, v) }
    end

    def add_attr_hash(h, fl, el)
      el.attributes.each do |k, v|
        h["count(#{fl}/@#{k})_isim"] ||= 0
        h["count(#{fl}/@#{k})_isim"] += 1

        h["#{fl}/@#{k}_ssim"] ||= []
        h["#{fl}/@#{k}_ssim"] += [normalize_text(el, v.text)]
      end
    end

    def xml_el_to_solr_fields(el)
      [
        el.path.gsub(/\[\d+\]/, ''),
        xml_el_with_attributes_to_solr_fields(el)
      ].flatten.uniq
    end

    def xml_el_with_attributes_to_solr_fields(el)
      return [nil] if el.document?

      @path_cache[el.pointer_id] ||= xml_el_with_attributes_to_solr_fields(el.parent).map do |p|
        base_name = "#{p}/#{el.name}"
        [base_name] + hierarchy_attributes(el).map do |k, v|
          [
            "#{base_name}[@#{k}=\"#{v}\"]",
            "#{base_name}[@#{k}]"
          ]
        end
      end.flatten.uniq
    end

    def hierarchy_attributes(el)
      el.attributes.reject { |k, _v| ['schemaLocation'].include? k }
    end

    def normalize_text(_el, v)
      v.gsub(/\s+/, ' ')
    end
  end
end
