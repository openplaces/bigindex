begin
  require 'yard'

  desc 'Generate documentation for Bigindex'
  YARD::Rake::YardocTask.new do |t|
    t.files = %w(- guides/*.rdoc)
    t.options = ["--title", "Bigindex Documentation"]
  end

  desc 'Generate documentation for Bigindex'
  task :rdoc => :yard
rescue LoadError
  puts "yard not available. Install it with: sudo gem install yard"
end
