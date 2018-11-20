class StockController < ApplicationController
  @@stock_deleted = false
  @@stocks = ['AAPL']

  def delete_stock()
    deleted_stock = params[:id]
    puts 'delete_stock func'
    puts deleted_stock
    deleted_index = @@stocks.index(deleted_stock)
    @@stock_deleted = true
    puts 'redirected'
    redirect_to action: 'index'
  end

  def index
    require 'net/http'
    require 'json'

    @data = []
    @max = 1
    @min = 1

    @table_data = []

    if @@stock_deleted
      @@stock_deleted = false
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
            puts "failed #{e2}"
          end

          puts "done done"

        end
        
      rescue => e
        puts "failed #{e}"
      end
    end

    @max += 0.05
    @min -= 0.05

    # @data = [{"name":"Data1","data":{"2013-02-10":3,"2013-02-17":3,"2013-02-24":3,"2013-03-03":1,"2013-03-10":4,"2013-03-17":3,"2013-03-24":2,"2013-03-31":3}},{"name":"Data2","data":{"2013-02-10":0,"2013-02-17":0,"2013-02-24":0,"2013-03-03":0,"2013-03-10":2,"2013-03-17":1,"2013-03-24":0,"2013-03-31":0}},{"name":"Data3","data":{"2013-02-10":0,"2013-02-17":1,"2013-02-24":0,"2013-03-03":0,"2013-03-10":0,"2013-03-17":1,"2013-03-24":0,"2013-03-31":1}},{"name":"Data4","data":{"2013-02-10":5,"2013-02-17":3,"2013-02-24":2,"2013-03-03":0,"2013-03-10":0,"2013-03-17":1,"2013-03-24":1,"2013-03-31":0}}]
  end
end
