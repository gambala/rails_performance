module RailsPerformance

  class Utils
    # date key in redis store
    def Utils.cache_key(now = Date.today)
      "date-#{now}"
    end

    # write to current slot
    # time - date -minute
    def Utils.field_key(now = Time.now)
      now.strftime("%H:%M")
    end

    def Utils.log_job_in_redis(e)
      key   = "jobs|queue|#{e[:queue]}|worker|#{e[:worker]}|jid|#{e[:jid]}|datetime|#{e[:datetime]}|created_ati|#{e[:created_ati]}|enqueued_ati|#{e[:enqueued_ati]}|start_timei|#{e[:start_timei]}|status|#{e[:status]}|END"
      value = { message: e[:message], duration: e[:duration] }
      Utils.save_to_redis(key, value)
    end

    def Utils.log_request_in_redis(e)
      value = e.slice(:view_runtime, :db_runtime, :duration, :HTTP_REFERER)
      key   = "performance|controller|#{e[:controller]}|action|#{e[:action]}|format|#{e[:format]}|status|#{e[:status]}|datetime|#{e[:datetime]}|datetimei|#{e[:datetimei]}|method|#{e[:method]}|path|#{e[:path]}|request_id|#{e[:request_id]}|END"
      Utils.save_to_redis(key, value)
    end

    def Utils.log_trace_in_redis(request_id, value)
      key = "trace|#{request_id}"
      Utils.save_to_redis(key, value, RailsPerformance::Reports::RecentRequestsReport::TIME_WINDOW.to_i)
    end

    def Utils.fetch_from_redis(query)
      #puts "\n\n   [REDIS QUERY]   -->   #{query}\n\n"

      keys   = RP.redis.keys(query)
      return [] if keys.blank?
      values = RP.redis.mget(keys)

      [keys, values]
    end

    def Utils.days
      ActiveSupport::Duration.build(RP.duration % 24.days).parts[:days] + 1
    end

    def Utils.median(array)
      sorted = array.sort
      size   = sorted.size
      center = size / 2

      if size == 0
        nil
      elsif size.even?
        (sorted[center - 1] + sorted[center]) / 2.0
      else
        sorted[center]
      end
    end

    def Utils.save_to_redis(key, value, expire = RP.duration.to_i)
      # puts "  [SAVE]    key  --->  #{key}\n"
      # puts "          value  --->  #{value.to_json}\n\n"
      RP.redis.set(key, value.to_json)
      RP.redis.expire(key, expire.to_i)
    end

  end
end