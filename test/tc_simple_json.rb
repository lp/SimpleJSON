require 'rubygems'
require 'test/unit'
require 'json'

# require File.join( File.dirname( File.expand_path(__FILE__)), '..','aws-sdb','lib','aws_sdb')
require 'aws_sdb'
require File.join( File.dirname( File.expand_path(__FILE__)), '..', 'lib', 'simple_json')

class TestSimpleJSONDB < Test::Unit::TestCase
	BEGIN {
		@@id = Time.now.to_i.to_s + rand(1000).to_s
	}
	
	def setup
		SimpleJSON.bootstrap(File.join( File.dirname( File.expand_path(__FILE__)), '..','simple_json_config.rb'))
	end
	
	def test_01_bootload
		@@sdb = AwsSdb::Service.new(:logger=>SimpleJSON::DB::LogDuck.new)
		config = eval(File.open(File.join( File.dirname( File.expand_path(__FILE__)), '..','simple_json_config.rb'), 'r').read)
		assert(@@sdb.list_domains[0].include?(config['AMAZON_DOMAIN']), 'boot?')
	end
	
	def test_02_firstset
		@@i_data = {@@id => {'name' => @@id, 'test' => 'done'}}
		
		o_data = SimpleJSON.rack_mock(:set, JSON.generate(@@i_data))
		assert(o_data.is_a?(Array),'return HTTP?')
		assert(o_data[0] == 200,'HTTP 200?')
		assert(o_data[1].is_a?(Hash),'HTTP Headers?')
		assert(o_data[1]['Content-Type'] == 'application/json', 'JSON?')
		assert(o_data[2].is_a?(String),'JSON String?')
		
		p_data = JSON.parse(o_data[2])
		assert(p_data.is_a?(Hash),'JSON Parse?')
		assert(p_data.include?(@@id),'returned ID?')
		assert(p_data[@@id] == true,'set is true?')
	end
	
	def test_03_get_one
		t_data = {@@id => nil}
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate(t_data))[2])
		@@i_data[@@id].each do |k,v|
			assert(o_data[@@id][k][0] == v, "get <#{k}> in first set")
		end
	end
	
	def test_04_get_one_attribute
		t_data = {@@id => {'name' => nil}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate(t_data))[2])
		assert(t_data[@@id].size == o_data[@@id].size, 'get one attribute')
	end
	
	def test_05_set_one_more
		t_data = {@@id => {'more' => 'data'}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:set, JSON.generate(t_data))[2])
		assert(o_data[@@id] == true,'set is true?')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => nil}))[2])
		@@i_data[@@id].merge!(t_data[@@id])
		@@i_data[@@id].each do |k,v|
			assert(o_data[@@id][k][0] == v, "get <#{k}> in first get")
		end
	end
	
	def test_06_set_overwrite
		o_data = JSON.parse( SimpleJSON.rack_mock(:set, JSON.generate({@@id => {'more' => 'data2'}}))[2])
		assert(o_data[@@id] == true,'set is true?')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => nil}))[2])
		assert(o_data[@@id]['more'].size == 1, 'overwrite data?')
	end
	
	def test_07_set_append
		o_data = JSON.parse( SimpleJSON.rack_mock(:add, JSON.generate({@@id => {'more' => 'data3'}}))[2])
		assert(o_data[@@id] == true,'set is true?')
    
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => nil}))[2])
		assert(o_data[@@id]['more'].size == 2, 'append data?')
	end
	
	def test_08_query_id_only
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate({'' => nil}))[2])
		assert(o_data.is_a?(Hash),'query all is not a Hash?')
		assert(o_data.size == 1,'query all Hash contains more than one key value pair')
		assert(o_data.has_key?(''),'query all Hash does not contain the query string as key')
		assert(o_data[''].to_a.map { |obj| obj[1] }.uniq.size == 1,'query all Hash does not bring id => nil? ')
	end
	
	def test_09_query_all
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate({'' => true}))[2])
		assert(o_data.is_a?(Hash),'query all is not a Hash?')
		assert(o_data.size == 1,'query all Hash contains more than one key value pair')
		assert(o_data.has_key?(''),'query all Hash does not contain the query string as key')
		assert(o_data[''].has_key?(@@id))
		assert(o_data[''][@@id].size > 1)
	end
	
	def test_10_query_specific_all
		query = "['name' = '#{@@id}']"
		t_data = {query => true}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data.is_a?(Hash),'query specific all is not a Hash?')
		assert(o_data.size == 1,'query specific all Hash contains more than one key value pair')
		assert(o_data.has_key?(query),'query specific all Hash does not contain the query string as key')
		assert(o_data[query].has_key?(@@id))
		assert(o_data[query][@@id].size == @@i_data[@@id].size)
	end
	
	def test_11_query_specific_none
		query = "['name' = '#{@@id}']"
		t_data = {query => nil}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data.is_a?(Hash))
		assert(o_data.size == 1)
		assert(o_data.has_key?(query))
		assert(o_data[query].has_key?(@@id))
		assert(o_data[query][@@id].nil?)
	end
	
	def test_12_query_specific_some
		query = "['name' = '#{@@id}']"
		t_data = {query => {'name' => nil, 'more' => nil}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data.is_a?(Hash))
		assert(o_data.size == 1)
		assert(o_data.has_key?(query))
		assert(o_data[query].has_key?(@@id))
		assert(o_data[query][@@id].size == 2)
	end
	
	def test_13_get_array_item
		o_data = JSON.parse( SimpleJSON.rack_mock(:add, JSON.generate({@@id => {'list' => 'item1'}}))[2])
		assert(o_data[@@id] == true,'add more again?')
		o_data = JSON.parse( SimpleJSON.rack_mock(:add, JSON.generate({@@id => {'list' => 'item2'}}))[2])
		assert(o_data[@@id] == true,'add more again?')
		o_data = JSON.parse( SimpleJSON.rack_mock(:add, JSON.generate({@@id => {'list' => 'item3'}}))[2])
		assert(o_data[@@id] == true,'add more again?')
		o_data = JSON.parse( SimpleJSON.rack_mock(:add, JSON.generate({@@id => {'list' => 'item4'}}))[2])
		assert(o_data[@@id] == true,'add more again?')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => {'list' => 0}}))[2])
		assert(o_data.is_a?(Hash))
		assert(o_data.include?(@@id))
		assert(o_data[@@id].include?('list'))
		assert(o_data[@@id]['list'] == 'item1')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => {'list' => 1}}))[2])
		assert(o_data[@@id]['list'] == 'item2')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => {'list' => 2}}))[2])
		assert(o_data[@@id]['list'] == 'item3')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => {'list' => 3}}))[2])
		assert(o_data[@@id]['list'] == 'item4')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => {'list' => 'first'}}))[2])
		assert(o_data[@@id]['list'] == 'item1')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => {'list' => 'last'}}))[2])
		assert(o_data[@@id]['list'] == 'item4')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => {'list' => '2..-1'}}))[2])
		assert(o_data[@@id]['list'].is_a?(Array))
		assert(o_data[@@id]['list'].size == 2)
		assert(o_data[@@id]['list'][0] == 'item3')
		assert(o_data[@@id]['list'][1] == 'item4')
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => {'list' => '0...2'}}))[2])
		assert(o_data[@@id]['list'].size == 2)
		assert(o_data[@@id]['list'][0] == 'item1')
		assert(o_data[@@id]['list'][1] == 'item2')
	end
	
	def test_14_query_array_item
		query = "['name' = '#{@@id}']"
		
		t_data = {query => {'list' => 0}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data[query][@@id]['list'] == 'item1')
		
		t_data = {query => {'list' => 1}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data[query][@@id]['list'] == 'item2')
		
		t_data = {query => {'list' => 2}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data[query][@@id]['list'] == 'item3')
		
		t_data = {query => {'list' => 3}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data[query][@@id]['list'] == 'item4')
		
		t_data = {query => {'list' => 'first'}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data[query][@@id]['list'] == 'item1')
		
		t_data = {query => {'list' => 'last'}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data[query][@@id]['list'] == 'item4')
		
		t_data = {query => {'list' => '2..-1'}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data[query][@@id]['list'][0] == 'item3')
		assert(o_data[query][@@id]['list'][1] == 'item4')
		
		t_data = {query => {'list' => '0...2'}}
		o_data = JSON.parse( SimpleJSON.rack_mock(:query, JSON.generate(t_data))[2])
		assert(o_data[query][@@id]['list'][0] == 'item1')
		assert(o_data[query][@@id]['list'][1] == 'item2')
	end
	
	def test_20_delete
		o_data = JSON.parse( SimpleJSON.rack_mock(:delete, JSON.generate({@@id => nil}))[2])
		assert(o_data.is_a?(Hash))
		assert(o_data.size == 1)
		assert(o_data.has_key?(@@id))
		assert(o_data[@@id] == true)
		
		o_data = JSON.parse( SimpleJSON.rack_mock(:get, JSON.generate({@@id => nil}))[2])
		assert(o_data.is_a?(Hash))
		assert(o_data.size == 1)
		assert(o_data.has_key?(@@id))
		assert(o_data[@@id].is_a?(Hash))
		assert(o_data[@@id].empty?)
	end
	
	def test_21_other_config
		domain = 'other_test_domain'
		o_data = JSON.parse( SimpleJSON.rack_mock(:delete, JSON.generate({@@id => nil}), {'AMAZON_DOMAIN' => domain})[2])
		assert(@@sdb.list_domains[0].include?(domain), 'other domain')
		@@sdb.delete_domain(domain)
	end
	
end