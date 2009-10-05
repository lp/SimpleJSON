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
						mem[obj[0]] = {'error', "SDB ERROR! Transaction returned: #{r_data.inspect}"}
					end 
				rescue => ex
					mem[obj[0]] =  {"error", "#{ex.class}: #{ex.message}"}
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
					return "Query Failed: v:#{v.inspect} | r:#{r_ids.inspect}"
				end
			end
		end
		
		def query_get(k,v)
			r_data = @sdb.get_attributes(@domain,k)
			if v.nil? || v == true || v == false
				r_data
			else
				v.to_a.inject(Hash.new) do |mem,obj|
					if obj[1].nil? || obj[1] == true || obj[1] == false
						mem[obj[0]] = r_data[obj[0]]
					elsif obj[1].is_a?(Integer)
						mem[obj[0]] = r_data[obj[0]][obj[1]]
					elsif obj[1] == 'first'
						mem[obj[0]] = r_data[obj[0]].first
					elsif obj[1] == 'last'
						mem[obj[0]] = r_data[obj[0]].last
					elsif obj[1] 	=~ /^([^\.]+)(\.\.\.*)([^\.]+)$/
						one = $1.to_i; three = $3.to_i
						if one.is_a?(Integer) and three.is_a?(Integer)
							if $2 == '..'
								mem[obj[0]] = r_data[obj[0]][one..three]
							elsif $2 == '...'
								mem[obj[0]] = r_data[obj[0]][one...three]
							else
								mem[obj[0]] = {'error' => "Bad slice syntax, you wrote: < #{$2} >, should have been < .. > or < ... >."}
							end
						else
							mem[obj[0]] = {'error' => "Bad slice syntax, must be 2 integers with dots in between... i.e. < 11..14 >"}
						end
					else
						mem[obj[0]] = {'error' => "Unknown key fetching syntax: #{obj[1].inspect}"}
					end
					mem
				end
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