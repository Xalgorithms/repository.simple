require 'grape'

require_relative './models'

class Rules < Grape::API
  format :json
  
  resource :rules do
    route_param :name do
      resource :versions do
        route_param :ver do
          get do
            args = { name: params.name, version: params.ver.to_i }
            rule = Rule.where(args).first
            error!(:not_found, 404) unless rule
            rule.content
          end
        end
      end
    end
  end
end
  
