# This generator bootstraps a Rails project for use with Bigindex
class BigindexGenerator < Rails::Generator::Base
 
  def initialize(runtime_args, runtime_options = {})
    require File.join(File.dirname(__FILE__), "..", "..", "install.rb")
    Dir.mkdir('lib/tasks') unless File.directory?('lib/tasks')
    super
  end
 
  def manifest
    record do |m|
      m.directory 'lib/tasks'
      m.file 'bigindex.rake', 'lib/tasks/bigindex.rake'
    end
  end
 
end