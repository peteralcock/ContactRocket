# encoding: UTF-8
require 'base64'
require 'multi_json'
require 'polipus'
require 'polipus-elasticsearch'

module Polipus
  module Storage
    class ElasticSearchStore < Base
      BINARY_FIELDS = %w(body headers user_data)
      DEFAULT_INDEX = Polipus::ElasticSearch::Page

      attr_accessor :index, :index_name, :except, :compress, :semaphore, :refresh

      def initialize(client, options = {})
        @index = options[:index] || options['index'] || DEFAULT_INDEX
        @index_name = options[:index_name] || options['index_name']
        @except = options[:except] || options['except'] || []
        @compress = options[:compress] || options['compress']
        @semaphore = Mutex.new
        @refresh = options[:refresh] || options['refresh'] || true
        index.setup(client, index_name)
        index.create_index!(index_name) unless index.index_exists?
      end

      def add(page)
        semaphore.synchronize do
          obj = page.to_hash
          Array(except).each { |field| obj.delete(field.to_s) }
          BINARY_FIELDS.each do |field|
            next if obj[field.to_s].nil? || obj[field.to_s].empty?
            obj[field.to_s] = MultiJson.encode(obj[field.to_s]) if field.to_s == 'user_data'
            obj[field.to_s] = Base64.encode64(obj[field.to_s])
          end
          obj['id'] = uuid(page)
          obj['fetched_at'] = obj['fetched_at'].to_i
          begin
            index.store(obj, refresh)
          rescue Elasticsearch::Transport::Transport::Errors::Conflict => ex
            # you're trying to store an old version.
          end
        end
      end

      def clear
        index.clear_index! if index.index_exists?
      end

      def count
        index.count
      end

      def drop
        index.delete_index! if index.index_exists?
      end

      def each
        # This method is implemented only for testing purposes
        response = index.client.search(
          index: index_name,
          body: {
            query: { match_all: {} },
            from: 0,
            size: 25
          }
        )
        response['hits']['hits'].each do |data|
          page = load_page(data['_source'])
          yield uuid(page), page
        end
      end

      def exists?(page)
        @semaphore.synchronize do
          index.exists?(uuid(page))
        end
      end

      def get(page)
        @semaphore.synchronize do
          load_page(index.get(uuid(page)))
        end
      end

      def remove(page)
        @semaphore.synchronize do
          index.remove(uuid(page), refresh)
        end
      end

      def load_page(data)
        return nil if data.nil?
        BINARY_FIELDS.each do |field|
          next if data[field.to_s].nil? || data[field.to_s].empty?
          data[field.to_s] = Base64.decode64(data[field.to_s])
          data[field.to_s] = MultiJson.decode(data[field.to_s]) if field.to_s == 'user_data'
        end
        page = Page.from_hash(data)
        page.fetched_at ||= 0
        page
      end
    end
  end
end
