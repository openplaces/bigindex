require File.join(File.dirname(__FILE__), 'support')

module BigIndex

  # = Index Fields
  #
  # Index fields define the blocks of information that should be used when
  # indexing (creation and retrieval) occurs for a class.
  #
  # Although these IndexField objects aren't created manually, they're
  # implicitly created from calls to the {BigIndex::Model#index} macro.
  #
  # At a minimum, an IndexField requires a name, and will then default to type
  # "text". In this case, the name needs to refer to a valid method (of
  # appropriate type), and will just implicitly index the return of that method.
  #
  #  class Book < BigRecord::Base
  #    include BigIndex::Resource
  #
  #    column :title, :string
  #
  #    index :title
  #  end
  #
  # Illustrated in the example above, we have the attribute "title" for this
  # given model Book, and we define an index field with just a the name :title.
  # From this, BigIndex will reference the #title method and index the return
  # of that method (string in this case) as the default index type :text.
  #
  # If a method doesn't exist for a given field name, then a block must be
  # attached to the {BigIndex::Model#index} macro, like the following example:
  #
  #  class Book < BigRecord::Base
  #    include BigIndex::Resource
  #
  #    column :title, :string
  #
  #    index :title
  #    index :title_exact_match, :string do |book|
  #      book.title
  #    end
  #  end
  #
  # The example above illustrates the same Book model as before, but now with a
  # new index field defined named "title_exact_match". Field names, after all,
  # can be named arbitrarily so a method might not exist for that name. The
  # notable difference here is that there is a block defined that accepts the
  # argument |book|. What happens in this case is that whenever indexing occurs
  # for a given Book record, it will pass the record object to this block and
  # index the returned value of the block. In this case, a new index field
  # needed to be defined that would match exact title names (:string type fields
  # cause exact matches), rather than the partial matches that get found from
  # type :text. So although there's only one attribute for this model, there are
  # many different ways we can index that value, and these decisions depend on
  # your application and indexing system.
  #
  class IndexField
    include Assertions

    attr_reader :field, :field_name, :field_type, :options, :block

    def initialize(params, block = nil)
      raise "IndexField requires at least a field name" unless params.size > 0

      @params = params.dup
      @block = block

      @field_name = params.shift
      assert_kind_of 'field_name', @field_name, Symbol, String

      unless params.empty? || ![Symbol, String].include?(params.first.class)
        @field_type = params.shift
      end

      @options = params.shift || {}
      assert_kind_of 'options', @options, Hash

      # Setting the default values
      @options[:finder_name] ||= field_name
      @field_type ||= :text
    end

    def [](name)
      @options[name]
    end

    def method_missing(name)
      @options[name.to_sym] || super
    end

  end

end # module BigIndex
