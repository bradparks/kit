package glee;

import haxe.macro.Context;

enum UniformType{
	Vec2;
	Vec4;
	Vec3;
	Matrix;
	Sampler2D;
	SamplerCube;
	Float;
	Int;
}

enum AttributeVecType{
	Float;
	Int;
}
enum AttributeType{
	Vec(type:AttributeVecType,num: Int);
	Float;
}

class GLSL{

	static var shaders : Map<String, GLSL> = new Map();

	static function unifyLineEndings(src:String):String {
		return StringTools.trim(src.split("\r").join("\n").split("\n\n").join("\n"));
	}

	static function pragmas(src:String):String {
		var lines = src.split("\n");
		var found:Bool = true;
		for (i in 0...lines.length) {
			var l = lines[i];
			if (l.indexOf("#pragma include") > -1) {
				var info = l.substring(l.indexOf('"') + 1, l.lastIndexOf('"'));
				lines[i] = pragmas(sys.io.File.getContent(info));
			}
		}
		return lines.join("\n");
	}

	static function parseAttributes(lines:Array<String>) : Map<String,AttributeType> {
		var attributes = new Map<String,AttributeType>();
		for (l in lines) {
			if (l.indexOf("attribute") > -1) {
				
				var source = StringTools.trim(l);
				var args = source.split(" ").slice(1);
				var attributeName = StringTools.trim(args[1].split(";").join(""));

				var attributeTypeString = args[0];
				var attributeType = switch(attributeTypeString){
					case "vec4": AttributeType.Vec(AttributeVecType.Float,4);
					case "vec3": AttributeType.Vec(AttributeVecType.Float,3);
					case "vec2": AttributeType.Vec(AttributeVecType.Float,2);
					case "float": AttributeType.Float;
					default: trace("attribute type not supported: " + attributeTypeString); null;
				}
				if(attributeType != null){
					attributes[attributeName] = attributeType;
				}
			}
		}
		return attributes;
	}

	static function parseUniforms(lines:Array<String>) : Map<String,UniformType> {
		var uniforms = new Map<String,UniformType>();
		for (l in lines) {
			if (l.indexOf("uniform") > -1) {
				var source = StringTools.trim(l);
				var args = source.split(" ").slice(1);
				var uniformName = StringTools.trim(args[1].split(";").join(""));
				var uniformTypeString = args[0];


				var annotation:Null<String>;
				var ai = source.indexOf("@");
				if (ai > -1) {
					var end = source.indexOf(" ", ai);
					if (end <0){
						end = source.length;
					}
					//annotation found, which?
					annotation = source.substr(ai, end);
					source = { var s = source.split(" "); s.shift(); s.join(" "); };
					switch(annotation) {
						case "@color": trace("Color anotation TODO");
						default: trace("Unknown annotation: " + annotation);
					}
				}
				
				var uniformType = switch(uniformTypeString){
					case "sampler2D": UniformType.Sampler2D;
					case "samplerCube": UniformType.SamplerCube;
					case "mat4": UniformType.Matrix;
					case "vec4": UniformType.Vec4;
					case "vec3": UniformType.Vec3;
					case "vec2": UniformType.Vec2;
					case "float": UniformType.Float;
					default: trace("uniform type not supported: " + uniformTypeString); null;
				}
				if(uniformType != null){
					uniforms[uniformName] = uniformType;
				}
			}
		}
		return uniforms;
	}

	static public function get(filePath : String) : GLSL{

		var id = filePath;
		if (shaders.exists(id)){
			return shaders[id];
		}

		var shaderSrc : String = null;
        if(filePath != null){
            shaderSrc = readFile(filePath);
        }

        var shader = parse(shaderSrc);

        shaders[id] = shader;

        return shader;
		
	}

	static private function parse(shader : String) : GLSL{
		var shaderSource = pragmas(unifyLineEndings(shader));
		var lines:Array<String> = shaderSource.split("\n");
		var uniforms = parseUniforms(lines);
		var attributes = parseAttributes(lines);
		return new GLSL(shader,attributes,uniforms);
	}

	public var attributes(default, null) : Map<String,AttributeType>;
	public var uniforms(default, null) : Map<String,UniformType>;
	public var source(default,null) : String;

	public function new(source : String, attributes : Map<String, AttributeType>, uniforms : Map<String, UniformType>){
		this.attributes = attributes;
		this.uniforms = uniforms;
		this.source = source;
	}

	static function readFile(path : String) : String{
		var pos = Context.currentPos();
		try {
            var p = Context.resolvePath(path);
            return sys.io.File.getContent(p);
        }
        catch(e:Dynamic) {
            Context.error('Failed to load file $path: $e', pos); 
            return null;
        }
	}

}