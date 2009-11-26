module BigIndex
  module Adapters

    # This {AbstractAdapter} defines the API needed by BigIndex to provide
    # indexing functionality by different indexers. For a concrete example
    # of an implemented adapter, refer to {SolrAdapter}.
    #
    class AbstractAdapter

      attr_reader :name, :options, :connection

      # BigIndex Adapter API methods ====================================


      def adapter_name
        'abstract'
      end

      def default_type_field
        raise NotImplementedError
      end

      def default_primary_key_field
        raise NotImplementedError
      end

      def process_index_batch(items, loop, options={})
        raise NotImplementedError
      end

      def drop_index(model)
        raise NotImplementedError
      end

      def get_field_type(field_type)
        field_type
      end

      def execute(request)
        raise NotImplementedError
      end

      def index_save(model)
        raise NotImplementedError
      end

      def index_destroy(model)
        raise NotImplementedError
      end

      def find_by_index(model, query, options={})
        raise NotImplementedError
      end

      def find_values_by_index(model, query, options={})
        raise NotImplementedError
      end

      def find_ids_by_index(model, query, options={})
        raise NotImplementedError
      end

      def optimize_index
        raise NotImplementedError
      end


      # End of BigIndex Adapter API ====================================

    private

      def initialize(name, options)
        @name = name
        @options = options
      end

    end

  end # module Adapters
end # module BigIndex
