class Book < BigRecord::Base
  include BigIndex::Resource

  #acts_as_solr :fields => [:title, :author, :description, :current_time]

  column 'attribute:title',       'string'
  column 'attribute:author',      'string'
  column 'attribute:description', 'string'

  index :name => :string
  index :author => :string
  index :description => :text

  def current_time
    Time.now.to_s
  end

end