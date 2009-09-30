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
	
	def self.echo(opts=nil)
		lambda { |env| CrashProof.wrap { Bootstrap.config(opts); Response.generate( Request.parse( Body.get(env))) }}
	end
	
	def self.set(opts=nil)
		lambda { |env| CrashProof.wrap { Bootstrap.config(opts); Response.generate( @@store.set( 		Request.parse( Body.get(env)))) }}
	end
	
	def self.add(opts=nil)
		lambda { |env| CrashProof.wrap { Bootstrap.config(opts); Response.generate( @@store.add( 		Request.parse( Body.get(env)))) }}
	end
	
	def self.delete(opts=nil)
		lambda { |env| CrashProof.wrap { Bootstrap.config(opts); Response.generate( @@store.delete(	Request.parse( Body.get(env)))) }}
	end
	
	def self.get(opts=nil)
		lambda { |env| CrashProof.wrap { Bootstrap.config(opts); Response.generate( @@store.get( 		Request.parse( Body.get(env)))) }}
	end
	
	def self.query(opts=nil)
		lambda { |env| CrashProof.wrap { Bootstrap.config(opts); Response.generate( @@store.query( 	Request.parse( Body.get(env)))) }}
	end
	
	def self.rack_mock(m,data,opts=nil)
		CrashProof.wrap { Bootstrap.config(opts); Response.generate( @@store.send( m, Request.parse( data))) }
	end
	
end
