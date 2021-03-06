package glee.macro;

import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.Functions;
import tink.macro.Member;
using tink.MacroApi;
using belt.MacroUtils;

class GPUBufferMacro{

    static var bufferTypes : Map<String,ComplexType> = new Map();

	macro static public function apply() : ComplexType{

        var pos = Context.currentPos();
		
		//trace("Building from generic");
        var classType = 
		switch (Context.getLocalType()) {
			case TInst(_,[t]):
				switch(t){
					case TInst(ref,_):
						 ref.get();
					case TMono(_): Context.error("need to specify the program type explicitely, no type inference",pos); null; 	
					default: null;
				}
			default: null;
		}

        if(null){
            return null;
        }

        var metadata = classType.meta.get();

        var shaderGroup = glee.macro.GPUProgramMacro.getShaderGroupFromMetadata(metadata);
        
        
        return getBufferClassFromAttributes(shaderGroup.attributes);
    }

    static public function getBufferClassFromAttributes(attributes : Array<glee.GLSLShaderGroup.Attribute>) : ComplexType{
        var pos = Context.currentPos();
        var bufferClassPath = getBufferClassPathFromAttributes(attributes);

        if (bufferTypes.exists(bufferClassPath.name)){
            //trace("already generated " + bufferClassPath.name);
            return bufferTypes[bufferClassPath.name];
        }


        var fields : Array<Field> = [];


        var getNumVerticesWrittenBody = macro {var max : Float = 0;};

        var rewindBody = macro {
        };
        

        var totalStride : Int = 0;
        for (attribute in attributes){
            var numValues = switch(attribute.type){
                case Vec(_,num):num;
                case Float:1;
            }
            totalStride+= numValues; //work for samme types attributes //TODO make it work for mixed types Int/Float...
        }         

        var stride = 0;   
        for (attribute in attributes){
            var attributeName = attribute.name;
            var attributeMetadataName = "_" + attributeName + "_bufferPosition";

            getNumVerticesWrittenBody.append(macro max = Math.max(max,$i{attributeMetadataName}));            

            rewindBody.append(macro  $i{attributeMetadataName} = 0);

            var numValues = switch(attribute.type){
                case Vec(_,num):num;
                case Float:1;
            }

            //////////////////////initialization //////////////////////////////////////////
            
            
            fields.push({
                name: attributeMetadataName,
                pos: pos,
                access: [APrivate],
                kind: FVar(macro : Int,macro 0), //TODO -1 or 0 ? 
                });
       

            /////////////////////// write function ////////////////////////////////////////////
            var body = macro {
                uploaded = false;
                if(_float32Array == null) {
                    _float32Array = new loka.util.Float32Array(512);
                }
                if (_float32Array.length <= $i{attributeMetadataName} * $v{totalStride} + $v{numValues}) {
                    var newArray = new loka.util.Float32Array(_float32Array.length * 2); //TODO inline growing in javascript
                    //TODO : copy values
                    _float32Array = newArray;
                }


                var pos : Int = $i{attributeMetadataName} * $v{totalStride} + $v{stride}; 
                $i{attributeMetadataName} ++;
            }

            for (i in 0...numValues){
                var arg = "v" + i;
                body.append(macro  _float32Array[pos+$v{i}] = $i{arg});
            }

            //trace(body.toString());

            var arguments = [];
            switch(attribute.type){
                case glee.GLSL.AttributeType.Vec(vecType,num):
                    for (i in 0...num){
                        arguments.push(
                        switch(vecType){
                            case glee.GLSL.AttributeVecType.Float:
                                Functions.toArg("v"+i,macro : Float);
                            case glee.GLSL.AttributeVecType.Int:
                                Functions.toArg("v"+i,macro : Int);
                        }
                        );
                    }
                case glee.GLSL.AttributeType.Float:
                    arguments.push(
                        Functions.toArg("v0",macro : Float)
                        ); 
            }
            
            fields.push(Member.method("write_" + attribute.name,Functions.func(body,arguments)));            
            stride+= numValues; //work for samme types attributes //TODO make it work for mixed types Int/Float...
        }

        getNumVerticesWrittenBody.append(macro return Std.int(max));
        fields.push(Member.method("getNumVerticesWritten",Functions.func(getNumVerticesWrittenBody)));        

        fields.push(Member.method("rewind",Functions.func(rewindBody)));


        var typeDefinition : TypeDefinition = {
            pos : pos,
            pack : bufferClassPath.pack,
            name : bufferClassPath.name,
            kind :TDClass({pack :["glee"], name: "GPUBufferBase"},[], false),
            fields:fields
        }
        Context.defineType(typeDefinition);


        var bufferType = TPath(bufferClassPath);
        bufferTypes[bufferClassPath.name] = bufferType;
        return bufferType;
    } 

    static private function getBufferClassPathFromAttributes(attributes : Array<glee.GLSLShaderGroup.Attribute>): TypePath{
        var bufferClassName =  "Buffer_";
        for (attribute in attributes){
            bufferClassName += attribute.name + attribute.type;
        }
        bufferClassName = StringTools.urlEncode(bufferClassName);
        bufferClassName = StringTools.replace(bufferClassName,"%","_");
        
        var bufferClassPath = {pack:["glee", "buffer"],name:bufferClassName};

        return bufferClassPath;
    }

    static private function generateFieldsFromTypeParameter(classBuilder : ClassBuilder):Void{

        var pos = Context.currentPos();

        var target = classBuilder.target;
        if (target.isInterface){
            return;
        }

       

	}
}