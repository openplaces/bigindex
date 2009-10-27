dir = File.expand_path(File.join(File.dirname(__FILE__), 'adapters')) + '/'

require dir + 'abstract_adapter'

%w[ solr ].each do |gem_name|
  begin
    require dir + "#{gem_name}_adapter"
  rescue LoadError, Gem::Exception
    # ignore it
  end
end
