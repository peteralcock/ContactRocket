require 'elasticsearch/model'

ENV['POLIPUS_ELASTICSEARCH_INDEX_SHARDS']    ||= '1'
ENV['POLIPUS_ELASTICSEARCH_INDEX_REPLICAS']  ||= '0'

module Polipus
  module ElasticSearch
    class Page
      include Elasticsearch::Model

      DEFAULT_INDEX_NAME = 'polipus-pages'
      document_type 'polipus_page'
      index_name DEFAULT_INDEX_NAME

      settings(
        index: {
          number_of_shards: ENV['POLIPUS_ELASTICSEARCH_INDEX_SHARDS'].to_i,
          number_of_replicas: ENV['POLIPUS_ELASTICSEARCH_INDEX_REPLICAS'].to_i
        }
      )
      mapping(_all: { enabled: false }) do
        indexes(
          :id,
          index: :not_analyzed
        )
        indexes(
          :body,
          type: :string
        )
        indexes(
          :code,
          type: :integer
        )
        indexes(
          :depth,
          type: :integer
        )
        indexes(
          :error,
          type: :string
        )
        indexes(
          :fetched,
          type: :boolean
        )
        indexes(
          :fetched_at,
          type: :integer
        )
        indexes(
          :headers,
          type: :string
        )
        indexes(
          :links,
          type: :string
        )
        indexes(
          :redirect_to,
          type: :string
        )
        indexes(
          :referer,
          type: :string
        )
        indexes(
          :response_time,
          type: :integer
        )
        indexes(
          :url,
          type: :string
        )
        indexes(
          :user_data,
          type: :string
        )
      end

      def self.client
        __elasticsearch__.client
      end

      def self.count
        client.count(index: index_name, type: document_type)['count'].to_i
      end

      def self.create_index!(name)
        index_name(name) unless name.nil?
        __elasticsearch__.create_index!(index: index_name)
      end

      def self.clear_index!
        client.delete_by_query(
          index: index_name,
           body: { query: { match_all: {} } }
        )
      end

      def self.delete_index!
        client.indices.delete(index: index_name)
      end

      def self.exists?(id)
        client.exists?(
          index: index_name,
          type: document_type,
          id: id
        )
      end

      def self.get(id)
        return unless exists?(id)
        client.get_source(
          index: index_name,
          type: document_type,
          id: id
        )
      end

      def self.index_exists?
        client.indices.exists?(index: index_name)
      end

      def self.process_document(obj)
        doc = { '_type' => document_type }
        properties.each do |p|
          doc[p.to_s] = obj.respond_to?(p.to_s) ? obj.send(p.to_s) : obj[p.to_s]
        end
        doc.reject { |_, value| value.nil? }
      end

      def self.properties
        mapping.to_hash[document_type.to_sym][:properties].keys.map { |k| k.to_s }
      end

      def self.remove(id, refresh = false)
        return unless exists?(id)
        client.delete(
          index: index_name,
          type: document_type,
          id: id,
          refresh: refresh,
          version: Time.now.to_i,
          version_type: :external
        )
      end

      def self.setup(client_, index_name = DEFAULT_INDEX_NAME)
        __elasticsearch__.client = client_
        self.index_name(index_name)
      end

      def self.store(document, refresh = false)
        document = process_document(document)
        client.index(
          index: index_name,
          type: document_type,
          id: document['id'],
          body: document,
          refresh: refresh,
          version: document['fetched_at'].to_i,
          version_type: :external
        )
        document['id']
      end
    end
  end
end
