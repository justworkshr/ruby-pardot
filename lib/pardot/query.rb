module Pardot
  module Query

    def query(object, params, retries=3)
      filtered_params = params.except(:ids, :email_type) 
      result = {}

      if object == 'email'
          params[:ids].each do |id|
            path = (params[:email_type] == 'email' ? "do/read/id/#{id[0]}?" : "do/stats/id/#{id[0]}?")
            if !result.empty?
              result['email'] << get_result(object, path, filtered_params, retries, id[0], params[:email_type])['email'][0]
            else
              result.merge!(get_result(object, path, filtered_params, retries, id[0], params[:email_type]))
            end
          end
      else
        path = '/do/query/'
        result.merge!(get_result(object, path, filtered_params, retries))
      end
      result
    end

    def get_result(object, path, params, retries, *args)
      response = get(object, path, params, num_retries=retries)
      get_result = process_result(response, object, params, id=args[0], email_type=args[1])
      get_result
    end

    def process_result(result, object, params, *args)
      result = result.map{ |k, v| [rename_data_key(object, k), v] }.to_h
      if args[1] == 'email_stat' and result['stats'].is_a?(Hash)
        result['total_results'] = 1
        result['stats'].transform_values! {|v| if v.include? '%' then v.to_f/100 else v end}
        new_result = {"id" => id=args[0]}.merge!(result['stats'])
        result['stats'] = [new_result]
        result['email'] = result.delete 'stats'
      elsif args[1] =='email'
        result['total_results'] = 1
        result['email']['message_text'] = result['email'].delete('message')['text']
        result['email'] = [result['email']]
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
