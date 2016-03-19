require_relative './registry_client'
require_relative './models'

task :register do
  rcl = RegistryClient.new

  puts "# looking up registry with url=#{rcl.registry_url}"
  m = Registry.where(url: rcl.registry_url).first
  
  if m
    puts "# exists (public_id=#{m.public_id})"
  else
    puts "# storing new registry"
    m = Registry.create(url: rcl.registry_url)
  end

  unless m.public_id
    puts "# registring with the registry"
    rcl.register(m.url) do |public_id|
      puts "# saving public_id=#{public_id}"
      m.update_attributes(public_id: public_id)
    end
  end
end

task :registries do
  Registry.all.each do |registry|
    puts "# public_id=#{registry.public_id}; url=#{registry.url}"
  end
end

def with_registry(public_id)
  puts "# locating registry details (public_id=#{public_id})"
  rm = Registry.where(public_id: public_id).first
  if rm
    yield(rm)
  else
    puts "! failed to locate details"
  end
end

def with_rule_files
  Dir['./*.json'].each do |fn|
    yield(File.basename(fn, '.json'), File.mtime(fn).to_i, MultiJson.decode(File.read(fn)))
  end
end

task :populate, [:public_id] do |t, args|
  with_registry(args.public_id) do |m|
    changes = []
    with_rule_files do |name, ver, content|
      puts "# processing (name=#{name}; ver=#{ver})"

      rule = Rule.where(name: name).first
      attrs = { name: name, version: ver, content: content }

      if rule && rule.version != ver
        puts "#   updating"
        rule.update_attributes(attrs)
        changes << rule
      elsif !rule
        puts "#   creating"
        changes << Rule.create(attrs)
      else
        puts "#   nothing to do"
      end
    end

    rcl = RegistryClient.new
    changes.each do |rule|
      rcl.update_rule(rule.name, rule.version, m.public_id) do |public_id|
        puts "#   public_id=#{public_id}"
      end
    end
  end
end

task :clear do
  [Rule, Registry].each(&:destroy_all)
end
