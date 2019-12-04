module Pardot
  module Query

    def query(object, params, retries=3)
      filtered_params = params.except(:ids) 
      result = {}
      it = 3 #remove

      if object == 'email'
        params[:ids].each do |id|
          if it == 0 then break end#remove
          path = "do/stats/id/#{id[0]}?"
          if !result.empty?
            result['email'] << get_result(object, path, filtered_params, retries, id[0])['email'][0]
          else
            result.merge!(get_result(object, path, filtered_params, retries, id[0]))
          end
          it -= 1#remove
        end
      else
        path = '/do/query/'
        result.merge!(get_result(object, path, filtered_params, retries))
      end
      result
    end

    def get_result(object, path, params, retries, *args)
      response = get(object, path, params, num_retries=retries)
      get_result = process_result(response, object, params, id=args[0])
      get_result
    end

    def process_result(result, object, params, *args)
      result = result.map{ |k, v| [rename_data_key(object, k), v] }.to_h
      if object == 'email' and result['stats'].is_a?(Hash)
        result['total_results'] = 1
        result['stats'].transform_values! {|v| if v.include? '%' then v.to_f/100 else v end}
        new_result = {"id" => id=args[0]}.merge!(result['stats'])
        result['stats'] = [new_result]
        result['email'] = result.delete 'stats'
      else
        result = result['result']
        result["total_results"] = result["total_results"].to_i if result["total_results"]
        result[object] = [result[object]] if result[object].is_a?(Hash)
      end
      result
    end

    def rename_data_key(object, key)
      if clean_key(object) == clean_key(key)
        return object
      else
        return key
      end
    end

    def clean_key(key)
      key.gsub('_', '').downcase
    end
  end
end
