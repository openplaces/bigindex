require File.dirname(__FILE__) + '/book' unless defined?(Book)

class Novel < Book

  column :publisher,    :string

  index :publisher, :text

end