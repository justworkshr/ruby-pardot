module Pardot
  module Query

    def query(object, params)
      path = '/do/query/'
      response = get(object, path, params)
      result = response["result"]
      result["total_results"] = result["total_results"].to_i if result["total_results"]
      result
    end

  end
end
