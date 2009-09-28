# ///////////////////////////////////////////////////////////////////////////////////////
# 
# Author:: lp (mailto:lp@spiralix.org)
# Copyright:: 2009 Louis-Philippe Perron - Released under the terms of the MIT license
# 
# :title:SimpleJSON
class SimpleJSON
	require File.join( File.dirname( File.expand_path(__FILE__)), 'store_helpers')
	
	BEGIN {
		require File.join( File.dirname( File.expand_path(__FILE__)), 'store_db')
		require File.join( File.dirname( File.expand_path(__FILE__)), 'store_bootstrap.rb')
		file = File.join( File.dirname( File.expand_path(__FILE__)), 'store_config.rb')
		if File.exist?(file)
			SimpleJSON::Bootstrap.config(file)
		end
	}
	
	def self.set(opts=nil)
		Bootstrap.config(opts)
		lambda { |env| Response.generate( @@store.set( 		Request.parse( env['rack.input'].read )))}
	end
	
	def self.add(opts=nil)
		Bootstrap.config(opts)
		lambda { |env| Response.generate( @@store.add( 		Request.parse( env['rack.input'].read )))}
	end
	
	def self.delete(opts=nil)
		Bootstrap.config(opts)
		lambda { |env| Response.generate( @@store.delete(	Request.parse( env['rack.input'].read )))}
	end
	
	def self.get(opts=nil)
		Bootstrap.config(opts)
		lambda { |env| Response.generate( @@store.get( 		Request.parse( env['rack.input'].read )))}
	end
	
	def self.query(opts=nil)
		Bootstrap.config(opts)
		lambda { |env| Response.generate( @@store.query( 	Request.parse( env['rack.input'].read )))}
	end
	
	def self.rack_mock(m,data,opts=nil)
		Bootstrap.config(opts)
		Response.generate( @@store.send( m, Request.parse( data)))
	end
	
end
