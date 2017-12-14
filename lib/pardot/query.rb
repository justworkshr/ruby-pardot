module Pardot
  module Query

    def query(object, params)
      path = '/do/query/'
      response = get(object, path, params)
      result = process_result(response["result"], object)
      result
    end

    def process_result(result, object)
      result["total_results"] = result["total_results"].to_i if result["total_results"]
      result = result.map{ |k, v| [rename_data_key(object, k), v] }.to_h
      result[object] = [result[object]] if result[object].is_a?(Hash)
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
