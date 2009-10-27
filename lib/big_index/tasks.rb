require 'rake' unless defined? Rake

Dir["#{File.join(File.dirname(__FILE__),"..")}/tasks/*.rake"].sort.each { |ext| load ext }