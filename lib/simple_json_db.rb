class SimpleJSON
	# ///////////////////////////////////////////////////////////////////////////////////////
	# 
	# Author:: lp (mailto:lp@spiralix.org)
	# Copyright:: 2009 Louis-Philippe Perron - Released under the terms of the MIT license
	# 
	# :title:SimpleJSON::DB
	class DB
		require 'aws_sdb'

		# id generated in client?
		# in js = < '' + date.getTime() + Math.floor(Math.random()*1000) >
		def initialize(domain)
			@domain = domain
			@sdb = AwsSdb::Service.new(:logger=>LogDuck.new)
			create_domain unless domain_exist?
		end

		def set(data)
			# in: data = {'id' => {:key1 => value1, :key2 => value2}}
			# out: data = {'id' => true} || {'id' => {"error"=>"message"}}
			parse(data) {|k,v| @sdb.put_attributes(@domain,k,v) }
		end

		def add(data)
			# in: data = {'id' => {:key1 => value1, :key2 => value2}}
			# out: data = {'id' => true} || {'id' => {"error"=>"message"}}
			parse(data) {|k,v| @sdb.put_attributes(@domain,k,v,false) }
		end

		def get(data)
			# in: data = {'id' => {:key1 => nil, :key2 => nil}}
			# out: data = {'id' => {:key1 => value1, :key2 => value2}}
			parse(data) { |k,v| query_get(k,v) }
		end

		def delete(data)
			# in: data = {'id' => nil}
			# out: data = {'id' => true}
			parse(data) {|k,v| @sdb.delete_attributes(@domain,k) }
		end

		def query(data)
			# in: data = {'query' => {:key1 => nil, :key2 => nil}}
			# out: data = {'id' => {:key1 => value1, :key2 => value2}}
			parse(data) {|k,v| query_domain(k,v) }
		end
		
		private

		def parse(data,&block)
			data.to_a.inject(Hash.new) do |mem,obj|
				begin
					r_data = block.call(obj[0],obj[1])
					if r_data.nil?
						mem[obj[0]] = true
					elsif r_data.is_a?(Hash)
						mem[obj[0]] = r_data
					else
						mem[obj[0]] = [false, "SDB Error. Unable to 'put attributes'"]
					end 
				rescue => ex
					mem[obj[0]] =  [false, "#{ex.class}: #{ex.message}"]
				end
				mem
			end
		end

		def query_domain(k,v)
			ids = get_id(k)
			if v.nil?
				return ids.inject(Hash.new) { |mem,obj| mem[obj] = nil; mem }
			else
				if ids.is_a?(Array)
					ids.inject(Hash.new) { |mem,id| mem[id] = query_get(id,v); mem }
				else
					return [false,"Query Failed: v:#{v.inspect} | r:#{r_ids.inspect}"]
				end
			end
		end
		
		def query_get(k,v)
			r_data = @sdb.get_attributes(@domain,k)
			if v.nil? || v == true || v == false
				r_data
			else
				v.to_a.inject(Hash.new) { |mem,obj| mem[obj[0]] = r_data[obj[0]]; mem }
			end
		end

		def get_id(q,token=nil)
			ids,q_id = @sdb.query(@domain,q,token)
			ids += get_id(q,q_id) if q_id != ''
			return ids
		end

		def create_domain
			@sdb.create_domain(@domain)
		end

		def domain_exist?
			domains, dummy = @sdb.list_domains
			domains.include?(@domain)
		end
		
		class LogDuck; def debug(*args); end; end
	end
end