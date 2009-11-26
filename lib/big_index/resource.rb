module BigIndex

  # A class that includes {BigIndex::Resource} will be mixed in with indexing
  # functionality from BigIndex.
  #
  # The {BigIndex::Model#index} macro should then be used to define the fields
  # to be indexed for that instance.
  #
  module Resource

    def self.included(model)
      model.class_eval do
        extend BigIndex::Model

        @indexed = true
        @index_configuration = {
          :fields => [],
          :additional_fields => nil,
          :exclude_fields => [],
          :auto_save => true,
          :auto_commit => true,
          :background => true,
          :include => nil,
          :facets => nil,
          :boost => nil,
          :if => "true",
          :type_field => model.index_adapter.default_type_field,
          :primary_key_field => model.index_adapter.default_primary_key_field,
          :default_boost => 1.0
        }

        after_save    :index_save
        after_destroy :index_destroy

        def self.inherited(child)
          child.index_configuration = self.index_configuration
        end

        class << self
          # Defines find_with_index() and find_without_index()
          alias_method_chain :find, :index
        end
      end
    end

    def index_adapter
      self.class.index_adapter
    end

    def index_configuration
      self.class.index_configuration
    end

    def indexed?
      self.class.indexed?
    end

    def record_id
      self.id
    end

    def index_type
      self.class.index_type
    end

    def index_id
      "#{index_type}:#{record_id}"
    end

    def index_save
      unless self.class.index_disabled || index_configuration[:auto_save] == false
        index_adapter.index_save(self)
      end
    end

    def index_destroy
      unless index_configuration[:auto_save] == false
        index_adapter.index_destroy(self)
      end
    end

  end # module Resource
end # module BigIndex
