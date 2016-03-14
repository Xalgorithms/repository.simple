require 'grape'

class Rules < Grape::API
  format :json
  
  resource :rules do
    route_param :name do
      resource :versions do
        route_param :ver do
          get do
            { actions: [], filters: [] }
          end
        end
      end
    end
  end
end
  
