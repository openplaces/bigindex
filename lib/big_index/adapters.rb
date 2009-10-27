dir = Pathname(__FILE__).dirname.expand_path + 'adapters'

require dir + 'abstract_adapter'

%w[ solr ].each do |gem_name|
  begin
    require dir + "#{gem_name}_adapter"
  rescue LoadError, Gem::Exception
    # ignore it
  end
end
