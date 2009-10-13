begin
  require 'jeweler'

  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "bigindex"
    gemspec.authors = ["openplaces.org"]
    gemspec.email = "bigrecord@openplaces.org"
    gemspec.homepage = "http://www.bigrecord.org"
    gemspec.summary = "A Rails plugin that drops into models and provides indexing functionality. Uses an adapter/repository pattern inspired by Datamapper to abstract the actual indexer used in the background, and exposes the model to a simple indexing API."
    gemspec.description = "A Rails plugin that drops into models and provides indexing functionality."
    gemspec.files = FileList["{examples,generators,lib,rails,spec,tasks,vendor}/**/*","init.rb","install.rb","Rakefile","VERSION"].to_a
    gemspec.extra_rdoc_files = FileList["MIT-LICENSE","README.rdoc"].to_a

    gemspec.add_development_dependency "rspec"
    gemspec.add_dependency "solr-ruby", ">= 0.0.7"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
