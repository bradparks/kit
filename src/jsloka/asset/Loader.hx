package jsloka.asset;

import jsloka.asset.Image;
import js.html.Document;



abstract Loader(Document){
	
	inline public function new(){
		this = js.Browser.document;
	}

	//TODO macro embedding of Image ?
	inline public function loadImage(url : String, success : Image->Void, error : String -> Void):Void{
		var image = new js.html.Image();
		image.onload = function(_){
			success(image);
		}
		image.onerror = function(_){
			error("failed to load " + url);
		}
		image.src = url;
	}

	//TODO macro embedding of Text
	inline public function loadText(url : String, success : String->Void, error : String -> Void):Void{
		var http = new haxe.Http(url);
		http.onData = success;
		http.onError = error;
		//TODO ? http.onStatus = 
		http.request();
	}
}