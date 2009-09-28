class SimpleJSON
	require 'json'
	# ///////////////////////////////////////////////////////////////////////////////////////
	# 
	# Author:: lp (mailto:lp@spiralix.org)
	# Copyright:: 2009 Louis-Philippe Perron - Released under the terms of the MIT license
	# 
	# :title:SimpleJSON::Request
	module Request
		def self.parse(data)
			JSON.parse(data)
		end
	end
	
	# ///////////////////////////////////////////////////////////////////////////////////////
	# 
	# Author:: lp (mailto:lp@spiralix.org)
	# Copyright:: 2009 Louis-Philippe Perron - Released under the terms of the MIT license
	# 
	# :title:SimpleJSON::Response
	module Response
		def self.generate(data)
			return [200, {	'Content-Type' => 'application/json' }, JSON.generate(data)]
		end
	end
	
end