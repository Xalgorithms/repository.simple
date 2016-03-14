require 'faraday'
require 'faraday_middleware'
require 'multi_json'

require_relative './models'

class Client
  def initialize
    @conn = Faraday.new(registry_url) do |f|
      f.request(:url_encoded)
      f.request(:json)
      f.response(:json, :content_type => /\bjson$/)
      f.adapter(Faraday.default_adapter)        
    end
  end

  def registry_url
    ENV.fetch('TATEV_REGISTRY_URL', 'http://localhost:3000')
  end
  
  def update_rule(name, version, repo_id)
    puts "> PUT /api/v1/rules/#{name}/#{version}"
    resp = @conn.put("/api/v1/rules/#{name}", rule: { version: version, repository: { id: repo_id } })
    puts "< #{resp.status}"
    if resp.success?
      yield(resp.body.fetch('public_id'))
    end
  end

  def register(url)
    puts "> POST /api/v1/repositories"
    resp = @conn.post('/api/v1/repositories', repository: { url: url })
    puts "< #{resp.status}"
    if resp.success?
      yield(resp.body.fetch('public_id'))
    end
  end
end

client = Client.new
changes = []

puts "# registering"
registry = Registry.where(url: client.registry_url).first
registry = Registry.create(url: client.registry_url) unless registry
client.register(registry.url) do |public_id|
  registry.update_attributes(public_id: public_id)
end unless registry.public_id

Dir['./*.json'].each do |fn|
  name = File.basename(fn, '.json')
  ver = File.mtime(fn).to_i
  rule = Rule.where(name: name).first
  attrs = { name: name, version: ver, content: MultiJson.decode(File.read(fn)) }
  puts "# processing #{fn}"
  if rule && rule.version != ver
    puts "# updating"
    rule.update_attributes(attrs)
    changes << rule
  elsif !rule
    puts "# creating"
    changes << Rule.create(attrs)
  else
    puts "# nothing"
  end
end

changes.each do |rule|
  client.update_rule(rule.name, rule.version, registry.public_id) do |id|
    puts "# rule is identified as #{id}"
  end
end
