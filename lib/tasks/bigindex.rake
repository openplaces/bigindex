namespace :bigindex do

  desc 'Generates a bigindex.yml config file and places it into your RAILS_ROOT/config folder. Creates bigindex.yml.sample if the file already exists.'
  task :generate_config do
    require File.join(File.dirname(__FILE__), "..", "..", "install.rb")
  end

  desc 'Rebuilds the index based on the models in your RAILS_ROOT/app/models folder that include BigIndex::Resource'
  task :rebuild_index => :environment do
    models = Dir.glob("#{RAILS_ROOT}/app/models/*.rb").map { |path| File.basename(path, ".rb").camelize.constantize }

    # Read in the rake options and set them to defaults if needed
    batch_size  = ENV['BATCH_SIZE'].to_i.nonzero? || 100
    clear_first = env_to_bool('CLEAR',    true)
    optimize    = env_to_bool('OPTIMIZE', true)

    # Grab all the models that are indexable
    models = models.select { |m| m.respond_to?(:indexed?) && m.indexed? }

    # Setting the options for the rebuild_index method
    options = {:batch_size => batch_size, :drop => clear_first, :optimize => optimize}
    finder_options = {:batch_size => batch_size}

    models.each do |model|
      model.rebuild_index(options, finder_options)
    end
  end

  desc 'Drops the index of all the models in your Rails app that include BigIndex::Resource'
  task :drop_index => :environment do
    models = Dir.glob("#{RAILS_ROOT}/app/models/*.rb").map { |path| File.basename(path, ".rb").camelize.constantize }

    # Grab all the models that are indexable
    models = models.select { |m| m.respond_to?(:indexed?) && m.indexed? }

    models.each do |model|
      model.drop_index
    end
  end

  def env_to_bool(env, default)
    env = ENV[env] || ''
    case env
      when /^true$/i then true
      when /^false$/i then false
      else default
    end
  end

end