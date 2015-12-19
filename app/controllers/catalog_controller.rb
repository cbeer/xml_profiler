class CatalogController < ApplicationController
  include Blacklight::Catalog

  before_action :add_facet_fields_from_context, only: :index

  configure_blacklight do |config|
    config.default_solr_params = {
      q: '*:*',
      fl: '*'
    }

    config.http_method = :post

    config.add_facet_field :root, field: :doc_root_ssim, label: 'Root Element'
    config.add_facet_fields_to_solr_request!

    config.add_index_field :document_tesim, label: 'Document', helper_method: :render_document_field
    config.add_show_field :document_tesim, label: 'Document', helper_method: :render_document_field
  end

  private

  def add_facet_fields_from_context
    return unless params[:f][:root].present?

    add_field_label = lambda do |field|
      field.label = field.field.sub(/_[is]sim/, '').sub(%r{/\*}, '').humanize
    end

    root = params[:f][:root].first.to_s

    blacklight_config.add_facet_field :top_level_elements, field: "#{root}/*_ssim", label: 'Top-Level Elements'
    blacklight_config.add_facet_field match: %r{^#{root}/@.+_ssim$}, limit: true, &add_field_label

    blacklight_config.add_facet_field match: %r{^#{root}/[^\[]+/\*_ssim$}, limit: true, &add_field_label
    blacklight_config.add_facet_field match: %r{^#{root}/.+/text\(\)_ssim$}, if: false, limit: true, &add_field_label
    blacklight_config.add_facet_field match: %r{^count\(#{root}/.+_isim$}, if: false, limit: true, &add_field_label

    if params[:f].any? { |k, v| k.match(/\*_ssim$/) && v.any? { |v1| v1 =~ /^@/ } }
      f = params[:f].select { |k, v| v.any? { |v1| v1 =~ /^@/ } }

      f.each do |k, v|
        v.select { |v1| v1 =~ /^@/ }.each do |v1|
          blacklight_config.add_facet_field match: %r{#{k.sub('/*_ssim', '')}/#{v1}_ssim}, limit: true, &add_field_label
          blacklight_config.add_facet_field match: %r{#{k.sub('/*_ssim', '')}\[#{v1}.*_[si]sim}, limit: true, &add_field_label
        end
      end
    end
  end
end
