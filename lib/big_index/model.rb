module BigIndex

  # This is the module that mixes in Class level behavior for a
  # {BigIndex::Resource}.
  #
  module Model

    def default_repository_name
      Repository.default_name
    end

    def repository_name
      Repository.context.any? ? Repository.context.last.name : default_repository_name
    end

    def repository(name = nil)
      @repository ||
        if block_given?
          BigIndex.repository(name || repository_name) { |*block_args| yield(*block_args) }
        else
          BigIndex.repository(name || repository_name)
        end
    end

    def index_adapter
      repository.adapter
    end

    def index_configuration
      begin
        config = {}
        config = @index_configuration.dup

        config[:fields] = @index_configuration[:fields].dup if @index_configuration[:fields]
        config[:exclude_fields] = @index_configuration[:exclude_fields].dup if @index_configuration[:exclude_fields]

        config
      rescue
       {}
      end
    end

    def index_configuration=(config)
      @index_configuration = config
    end

    ##
    # Whenever a Ruby class includes BigIndex::Resource, it'll be considered
    # as indexed.
    #
    # This method checks whether the current class, as well as any ancestors
    # in its inheritance tree, is indexed.
    #
    # @return [TrueClass, FalseClass] whether or not the current class, or any
    #   of its ancestors are indexed.
    #
    def indexed?
      if @indexed.nil?
        @indexed = false
        ancestors.each do |a|
          if a.respond_to?(:indexed?) and a.indexed?
            @indexed = true
            break
          end
        end
      end
      @indexed
    end

    ##
    # The index_type will be the name of the model class by default.
    #
    # @return [String]
    #
    def index_type
      name
    end

    ##
    # Toggle the indexing on/off temporarily for the class.
    #
    # @param [Boolean] Pass true to disable indexing, false otherwise
    #
    def index_disabled= bool
      @index_disabled = bool
    end

    ##
    # Get the status of whether indexing is disabled or not.
    #
    # @return [Boolean] True if indexing is disabled. False otherwise.
    #
    def index_disabled
      @index_disabled ||= false
    end

    ##
    # Dispatches a command to the current adapter to rebuild the index.
    #
    # @return <Integer> representing number of items processed.
    #
    def rebuild_index(options={}, finder_options={})
      logger.info "=== Rebuilding index for: #{self.index_type}" unless options[:silent]

      if options[:drop]
        logger.info "Dropping index for: #{self.index_type}" unless options[:silent]
        index_adapter.drop_index(self)
      end

      finder_options[:batch_size] ||= 100
      finder_options[:view] ||= :all
      finder_options[:bypass_index] = true

      options[:batch_size] ||= 100
      options[:commit] = true unless options.has_key?(:commit)
      options[:optimize] = true unless options.has_key?(:optimize)

      logger.info "Offset: #{finder_options[:offset]}" unless options[:silent]
      logger.info "Stop row: #{finder_options[:stop_row]}" unless options[:silent]

      buffer = []
      items_processed = 0
      loop = 0

      # Depending on whether the model has a scan or find method, use that.
      # scan is from Bigrecord models, and find is from Activerecord.
      if self.respond_to?(:scan)
        self.scan(finder_options) do |r|
          items_processed += 1
          buffer << r
          if buffer.size > options[:batch_size]
            loop += 1
            index_adapter.process_index_batch(buffer, loop, options)
            buffer.clear
          end
        end

        index_adapter.process_index_batch(buffer, loop, options) unless buffer.empty?
      elsif self.respond_to?(:find)
        ar_options = {:limit => finder_options[:batch_size]}

        while
          loop += 1

          buffer = self.find_without_index(:all, ar_options)
          break if buffer.empty?
          items_processed += buffer.size

          index_adapter.process_index_batch(buffer, loop, options)

          break if buffer.size < finder_options[:batch_size]

          buffer.clear
          ar_options[:offset] = (loop * finder_options[:batch_size])+1
        end
      else
        raise "Your model needs at least a scan() or find() method"
      end

      if items_processed > 0
        logger.info "Index for #{self.index_type} has been rebuilt (#{items_processed} records)." unless options[:silent]
      else
        logger.info "Nothing to index for #{self.index_type}." unless options[:silent]
      end

      logger.info "=== Finished rebuilding index for: #{self.index_type}" unless options[:silent]

      return items_processed
    end

    ##
    # Drops the index for the current model.
    #
    # @return [TrueClass, FalseClass] whether the index was dropped.
    #
    def drop_index
      index_adapter.drop_index(self)
    end

    def index_view(name, columns)
      write_inheritable_attribute(:index_views_hash, read_inheritable_attribute(:index_views_hash) || default_index_views_hash)
      read_inheritable_attribute(:index_views_hash)[name] = columns
    end

    def index_views
      @index_views ||= index_views_hash.values
    end

    def index_view_names
      @index_view_names ||= index_views_hash.keys
    end

    def index_views_hash
      read_inheritable_attribute(:index_views_hash) || default_index_views_hash
    end

    def default_index_views_hash
      {:default => self.index_configuration[:fields]}
    end

    def index_fields(view_name = :default)
      field_list = index_views_hash[view_name]

      index_configuration[:fields].select{|field| field_list.include?(field.field_name)}
    end

    def index_field(field_name)
      field_name = field_name.to_s
      if index_configuration[:fields].map(&:field_name).map(&:to_s).include?(field_name)
        index_configuration[:fields].select{|field| field.field_name.to_s == field_name}.first
      end
    end

    def required_index_fields
      [index_configuration[:type_field], index_configuration[:primary_key_field], :id]
    end

    ##
    # Macro for defining a class attribute as an indexed field.
    #
    # Also creates the corresponding attribute finder method, which defaults
    # to the field name. This can be defined with the
    # :finder_name => "anothername" option.
    #
    # Refer to {IndexField} for more information on defining fields.
    #
    def index(*params, &block)
      index_field = IndexField.new(params, block)

      add_index_field(index_field)

      # Create the attribute finder method
      define_finder index_field[:finder_name]
    end

    ##
    # Class #find method
    #
    # From - alias_method_chain :find, :index
    #
    # This redefines the original #find method of the class, and
    # replaces it with an indexed version of #find. The indexed version can be
    # bypassed (dispatch to original instead) by passing :bypass_index => true
    #
    # The instantiated records either as a single object (case of :first),
    # or as an array of objects. When the option :raw_result => true
    # is passed to it, it will return a result object specific to the indexer used.
    # In the case of Solr, it will return a SolrResult object for example.
    #
    def find_with_index(*args)
      options = args.extract_options!
      unless options[:bypass_index]
        case args.first
          when :first then
            validate_index_find_options(options)
            find_every_by_index(options.merge({:limit => 1})).first
          when :all   then
            validate_index_find_options(options)
            find_every_by_index(options)
          else
            find_from_ids(args, options)
        end
      else
        options.delete(:bypass_index)
        find_without_index(*(args + [options]))
      end
    end

    ##
    # Indexed find method called by {#find_with_index} and dispatches
    # the actual search to the adapter.
    #
    def find_every_by_index(options={})
      # Construct the query. First add the type information.
      query =""

      # set default operator
      options[:operator] ||= :or

      # First add the conditions predicates
      conditions = options[:conditions]
      if conditions.is_a?(String)
        query << conditions
      elsif conditions.is_a?(Array) and !conditions.empty?
        nb_conditions = conditions.size - 1
        i = 0
        query << conditions[0].gsub(/\?/) do |c|
          i += 1
          raise ArgumentError, "Missing condition argument" unless i <= nb_conditions
          "#{conditions[i]}"
        end
      elsif conditions.is_a?(Hash) and !conditions.empty?
        conditions.each do |k, v|
          query << "#{k}:#{v} "
        end
      end

      fields =
        if options[:fields]
          options[:fields]
        else
          fields = options[:view] ? index_views_hash[options[:view]] : index_views_hash[:default]
          fields ||= []
        end

      if options[:format] == :ids
        index_adapter.find_ids_by_index(self, query, {  :offset   => options[:offset],
                                                  :order    => options[:order],
                                                  :limit    => options[:limit],
                                                  :fields   => fields,
                                                  :operator => options[:operator],
                                                  :raw_result => options[:raw_result]})
      else
        index_adapter.find_by_index(self, query, {  :offset   => options[:offset],
                                              :order    => options[:order],
                                              :limit    => options[:limit],
                                              :operator => options[:operator],
                                              :raw_result => options[:raw_result]})
      end

    end

    INDEX_FIND_OPTIONS = [ :source, :offset, :limit, :conditions, :order,
      :group, :fields, :debug, :view, :format, :raw_result ]

    ##
    # Validates the options passed to the find methods based on the accepted keys
    # defined in {INDEX_FIND_OPTIONS}
    #
    def validate_index_find_options(options)
      options.assert_valid_keys(INDEX_FIND_OPTIONS)
    end


  private

    def add_index_field(index_field)
      configuration = @index_configuration
      if configuration[:fields]
        unless configuration[:fields].include?(index_field)
          configuration[:fields] << index_field
        else
          return
        end
      else
        configuration[:fields] = [index_field]
      end

      define_method("#{index_field.field_name}_for_index") do
        index_field.block ? index_field.block.call(self) : self.send(index_field.field_name.to_sym)
      end
    end

    ##
    # Creates the attribute finder methods based on the indexed fields of the class,
    # i.e. #find_by_#{attribute_name}
    #
    def define_finder(finder_name)
      class_eval <<-end_eval
        def self.find_all_by_#{finder_name}(user_query, options={})
          options[:fields] ||= index_views_hash[:default]

          # quote the query if the field type is :string
          if finder_field = index_field(:#{finder_name})
            ([:string, :string_array].member?(finder_field.field_type)) ?
              query = "#{finder_name}:(\\"\#{user_query}\\")" : query = "#{finder_name}:(\#{user_query})"
          else
            query = user_query
          end

          if options[:format] == :ids
            index_adapter.find_ids_by_index(self, query, options)
          else
            index_adapter.find_by_index(self, query, options)
          end
        end

        def self.find_by_#{finder_name}(user_query, options={})
          find_all_by_#{finder_name}(user_query, options.merge({:limit => 1})).first
        end
      end_eval
    end

  end
end # module BigIndex