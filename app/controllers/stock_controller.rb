class StockController < ApplicationController
  @@stocks = []
  @@stock_deleted = false
  @@stock_added = false
  @@cache_data = []
  @@cache_table_data = []
  @@cache_max = 1
  @@cache_min = 1
  @@persisted_error = false
  @@stock_validation = false

  def add_stock()
    add_stock = params[:stock]

    begin
      url_2 = 'https://query1.finance.yahoo.com/v1/finance/search?q=' + add_stock + '&quotesCount=1'
      uri_2 = URI(url_2)
      resp_2 = Net::HTTP.get(uri_2)
      resp_json_2 = JSON.parse(resp_2)

      stock_metadata_info = resp_json_2['quotes']

      if stock_metadata_info.length == 0
        @@stock_validation = true
      else
        stock_metadata = stock_metadata_info[0]

        if stock_metadata['quoteType'] != 'ETF' && stock_metadata['quoteType'] != 'EQUITY'
          @@stock_validation = true
        else
          puts 'else'
          url = 'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&apikey=GJW2HJK06R4D18XC&symbol=' + add_stock
          uri = URI(url)
          resp = Net::HTTP.get(uri)
          resp_json = JSON.parse(resp)

          stock_info = resp_json["Time Series (Daily)"]
          chart_data = {}
          chart_data['name'] = add_stock
          chart_data['data'] = {}
          
          chart_keys = stock_info.keys
          chart_keys.sort
          last_key = chart_keys[-1]
          base_val = stock_info[last_key]['4. close'].to_f

          all_vol = 0

          prev_max = @@cache_max
          prev_min = @@cache_min
          
          stock_info.each do |key, val|
            stock_value = val['4. close'].to_f / base_val
            @@cache_max = stock_value > @@cache_max ? stock_value : @@cache_max
            @@cache_min = stock_value < @@cache_min ? stock_value : @@cache_min
            chart_data['data'][key] = stock_value
            all_vol += val['5. volume'].to_f
          end

          if @@cache_max != prev_max
            @@cache_max += 0.05
          end

          if @@cache_min != prev_min
            @@cache_min -= 0.05
          end
          
          @@cache_data.push(chart_data)

          table_info = {}
          table_info['company'] = stock_metadata['shortname']
          table_info['symbol'] = add_stock
          table_info['type'] = stock_metadata['typeDisp']

          first_key = chart_keys[0]
          table_info['close_price'] = stock_info[first_key]['4. close']
          table_info['change'] = (stock_info[first_key]['4. close'].to_f / base_val).round(4)
          table_info['last_vol'] = (stock_info[first_key]['5. volume'].to_f / 1000000).round(5)
          table_info['avg_vol'] = (all_vol / (stock_info.length * 1000000)).round(5)

          @@cache_table_data.push(table_info)
        end
      end

      puts "done done"
    rescue => e
      @@persisted_error = true
      puts "failed #{e}"
    end

    if @@persisted_error == false
      @@stocks.push(add_stock)
    end

    @@stock_added = true

    puts 'redirected'
    redirect_to action: 'index'
  end

  def delete_stock()
    deleted_stock = params[:id]
    puts 'delete_stock func'
    puts deleted_stock
    deleted_index = @@stocks.index(deleted_stock)
    @@stocks.delete_at(deleted_index)
    @@cache_data.delete_at(deleted_index)
    @@cache_table_data.delete_at(deleted_index)
    @@stock_deleted = true
    puts 'redirected'
    redirect_to action: 'index'
  end

  def index
    require 'net/http'
    require 'json'

    @error = false
    @data = []
    @max = 1
    @min = 1

    @table_data = []
    @invalid_stock = false

    if @@stock_deleted
      @@stock_deleted = false
      @data = @@cache_data
      @table_data = @@cache_table_data
      @max = @@cache_max
      @min = @@cache_min
    elsif @@stock_added
        @@stock_added = false

        if @@stock_validation
          @invalid_stock = true
        elsif @@persisted_error
          @error = true
          @@persisted_error = false
        else
          @data = @@cache_data
          @table_data = @@cache_table_data
          @max = @@cache_max
          @min = @@cache_min
        end
    else
      begin
        @@stocks.each do |stock|
          url = 'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&apikey=GJW2HJK06R4D18XC&symbol=' + stock
          uri = URI(url)
          resp = Net::HTTP.get(uri)
          resp_json = JSON.parse(resp)

          stock_info = resp_json["Time Series (Daily)"]
          chart_data = {}
          chart_data['name'] = stock
          chart_data['data'] = {}
          
          chart_keys = stock_info.keys
          chart_keys.sort
          last_key = chart_keys[-1]
          base_val = stock_info[last_key]['4. close'].to_f

          all_vol = 0
          
          stock_info.each do |key, val|
            stock_value = val['4. close'].to_f / base_val
            @max = stock_value > @max ? stock_value : @max
            @min = stock_value < @min ? stock_value : @min
            chart_data['data'][key] = stock_value
            all_vol += val['5. volume'].to_f
          end
          
          @data.push(chart_data)
          @@cache_data = @data

          begin
            url_2 = 'https://query1.finance.yahoo.com/v1/finance/search?q=' + stock + '&quotesCount=1'
            uri_2 = URI(url_2)
            resp_2 = Net::HTTP.get(uri_2)
            resp_json_2 = JSON.parse(resp_2)

            stock_metadata = resp_json_2['quotes'][0]

            table_info = {}
            table_info['company'] = stock_metadata['shortname']
            table_info['symbol'] = stock
            table_info['type'] = stock_metadata['typeDisp']

            first_key = chart_keys[0]
            table_info['close_price'] = stock_info[first_key]['4. close']
            table_info['change'] = (stock_info[first_key]['4. close'].to_f / base_val).round(4)
            table_info['last_vol'] = (stock_info[first_key]['5. volume'].to_f / 1000000).round(5)
            table_info['avg_vol'] = (all_vol / (stock_info.length * 1000000)).round(5)

            @table_data.push(table_info)
          rescue => e2
            @error = true
            puts "failed #{e2}"
          end

          @@cache_table_data = @table_data

          puts "done done"

        end
        
      rescue => e
        @error = true
        puts "failed #{e}"
      end

      @max += 0.05
      @min -= 0.05

      @@cache_max = @max
      @@cache_min = @min
    end

    # @data = [{"name":"Data1","data":{"2013-02-10":3,"2013-02-17":3,"2013-02-24":3,"2013-03-03":1,"2013-03-10":4,"2013-03-17":3,"2013-03-24":2,"2013-03-31":3}},{"name":"Data2","data":{"2013-02-10":0,"2013-02-17":0,"2013-02-24":0,"2013-03-03":0,"2013-03-10":2,"2013-03-17":1,"2013-03-24":0,"2013-03-31":0}},{"name":"Data3","data":{"2013-02-10":0,"2013-02-17":1,"2013-02-24":0,"2013-03-03":0,"2013-03-10":0,"2013-03-17":1,"2013-03-24":0,"2013-03-31":1}},{"name":"Data4","data":{"2013-02-10":5,"2013-02-17":3,"2013-02-24":2,"2013-03-03":0,"2013-03-10":0,"2013-03-17":1,"2013-03-24":1,"2013-03-31":0}}]
  end
end
