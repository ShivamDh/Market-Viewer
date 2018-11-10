class StockController < ApplicationController
	@@api_key = "GJW2HJK06R4D18XC"
	@@stocks = ['AAPL']

	def index
		require 'net/http'
		require 'json'

		@data = []
		@max = 1
		@min = 1

		@table_data = []

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
				rescue => e2
					puts "failed #{e2}"
				end

				puts "done done"

			end
			
		rescue => e
			puts "failed #{e}"
		end

		@max += 0.05
		@min -= 0.05

		# @data = [{"name":"Data1","data":{"2013-02-10":3,"2013-02-17":3,"2013-02-24":3,"2013-03-03":1,"2013-03-10":4,"2013-03-17":3,"2013-03-24":2,"2013-03-31":3}},{"name":"Data2","data":{"2013-02-10":0,"2013-02-17":0,"2013-02-24":0,"2013-03-03":0,"2013-03-10":2,"2013-03-17":1,"2013-03-24":0,"2013-03-31":0}},{"name":"Data3","data":{"2013-02-10":0,"2013-02-17":1,"2013-02-24":0,"2013-03-03":0,"2013-03-10":0,"2013-03-17":1,"2013-03-24":0,"2013-03-31":1}},{"name":"Data4","data":{"2013-02-10":5,"2013-02-17":3,"2013-02-24":2,"2013-03-03":0,"2013-03-10":0,"2013-03-17":1,"2013-03-24":1,"2013-03-31":0}}]
	end
end
