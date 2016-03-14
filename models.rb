require 'mongoid'

Mongoid.load!('mongoid.yml')

class Rule
  include Mongoid::Document

  field :name, type: String
  field :version, type: Integer
  field :content, type: Hash
end

class Registry
  include Mongoid::Document

  field :url, type: String
  field :public_id, type: String
end
