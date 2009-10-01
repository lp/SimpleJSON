require 'rack'
require File.join( File.dirname( File.expand_path(__FILE__)), 'simple_json')

SimpleJSON.bootstrap('simple_json_config.rb')
run Rack::URLMap.new(
	'/echo'			=> SimpleJSON.echo,
	'/set' 			=> SimpleJSON.set,
	'/add'			=> SimpleJSON.add,
	'/delete' 	=> SimpleJSON.delete,
	'/get' 			=> SimpleJSON.get,
	'/query' 		=> SimpleJSON.query
)
