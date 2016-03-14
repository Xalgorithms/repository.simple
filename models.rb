require 'mongoid'

Mongoid.load!('mongoid.yml')

class Rule
  include Mongoid::Document

  field :name, type: String
  field :version, type: Integer
  field :content, type: Hash
end
