require 'big_index'

def config_file
  "#{RAILS_ROOT}/config/bigindex.yml"
end

def full_config
  begin
    YAML::load(File.open(config_file))
  rescue
    puts "Missing environment '#{RAILS_ENV}' in config file #{config_file}"
    return {}
  end
end

def get_config_for_environment
  if hash = full_config[RAILS_ENV]
    BigIndex.symbolize_keys(hash)
  elsif hash = full_config[RAILS_ENV.to_sym]
    hash
  else
    {}
  end
end


BigIndex.setup(:default, get_config_for_environment) unless get_config_for_environment.empty?