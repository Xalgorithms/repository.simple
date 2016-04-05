require 'faraday'
require 'faraday_middleware'
require 'multi_json'

class RegistryClient
  def initialize(url)
    @conn = Faraday.new(url) do |f|
      f.request(:url_encoded)
      f.request(:json)
      f.response(:json, :content_type => /\bjson$/)
      f.adapter(Faraday.default_adapter)        
    end
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
