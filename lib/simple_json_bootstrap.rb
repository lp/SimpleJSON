class SimpleJSON
	def self.bootstrap(opts)
		Bootstrap.config(opts)
	end
	# ///////////////////////////////////////////////////////////////////////////////////////
	# 
	# Author:: lp (mailto:lp@spiralix.org)
	# Copyright:: 2009 Louis-Philippe Perron - Released under the terms of the MIT license
	# 
	# :title:SimpleJSON::Bootstrap
	module Bootstrap
		def self.config(opts)
			unless opts.nil?
				opts = eval(File.open(opts, 'r').read) if opts.is_a?(String)
				if opts.is_a?(Hash)
					change = Hash.new
					if opts['AMAZON_ACCESS_KEY_ID'] and ENV['AMAZON_ACCESS_KEY_ID'] != opts['AMAZON_ACCESS_KEY_ID']
						ENV['AMAZON_ACCESS_KEY_ID'] = opts['AMAZON_ACCESS_KEY_ID']
						change[:@access_key_id] = opts['AMAZON_ACCESS_KEY_ID']
					end
					if opts['AMAZON_SECRET_ACCESS_KEY'] and ENV['AMAZON_SECRET_ACCESS_KEY'] != opts['AMAZON_SECRET_ACCESS_KEY']
						ENV['AMAZON_SECRET_ACCESS_KEY'] = opts['AMAZON_SECRET_ACCESS_KEY']
						change[:@secret_access_key] = opts['AMAZON_SECRET_ACCESS_KEY']
					end
					
					if SimpleJSON.class_variables.include?('@@store') and ( ! change.empty? or opts['AMAZON_DOMAIN'])
						store = SimpleJSON.class_eval { class_variable_get(:@@store) }
						if ! change.empty?
							sdb = store.instance_variable_get(:@sdb)
							change.each do |k,v|
								sdb.instance_variable_set(k,v)
							end
						end
						if opts['AMAZON_DOMAIN']
							store.instance_variable_set(:@domain,opts['AMAZON_DOMAIN'])
							store.instance_eval('create_domain unless domain_exist?')
						end
					else
						store = SimpleJSON::DB.new(opts['AMAZON_DOMAIN']) if opts['AMAZON_DOMAIN']
						SimpleJSON.class_eval { class_variable_set(:@@store, store) }
					end
				end
			end
		end
	end
end