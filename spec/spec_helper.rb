require 'pathname'
require 'rubygems'
require 'spec'

SPEC_ROOT = File.expand_path(File.join(File.dirname(__FILE__))) + '/'

# Now we'll initialize the ORM connection
begin
  require 'connection'
rescue LoadError
  # Default to BigRecord if none was defined.
  require File.join(File.dirname(__FILE__), 'connections', 'bigrecord', 'connection')
  BigRecord::Base.logger.info "No data store defined. Defaulting to BigRecord..."
end

# Now we can require BigIndex
require SPEC_ROOT + "../lib/big_index"

CONFIGURATION_FILE_OPTIONS = YAML.load(File.new(File.dirname(__FILE__) + '/connections/bigindex.yml')).freeze
BigIndex.configurations = CONFIGURATION_FILE_OPTIONS

# @model_path was set in the connection.rb file, and it's the path where the models are defined.
Dir.glob( @model_path ).each do |model|
  require model
end
