package korrigan;

import glmat.Vec4;
import korrigan.TextureAtlas.CutOut;

typedef TexturedQuadMeshData =  {x1:Float,y1:Float, x2:Float,y2:Float,u1:Float,v1:Float, u2:Float,v2:Float, refX : Float, refY : Float};
typedef FrameData = {textureCutOut : String, ?meshData : TexturedQuadMeshData, ?scaleX : Float, ?scaleY : Float};
typedef AnimationData = Array<FrameData>; //TODO add timing....
typedef SpriteData = Map<String,AnimationData>;
typedef SpriteDataSet = Map<String,SpriteData>;

typedef TexturePlacement = {
	//textureId :textureCutOut.textureId,
    srcX1 : Float,
    srcY1 : Float,
    srcX2 : Float,
    srcY2 : Float,
    dstX1 : Float,
    dstY1 : Float,
    dstX2 : Float,
    dstY2 : Float,
    dstX3 : Float,
    dstY3 : Float,
    dstX4 : Float,
    dstY4 : Float,
    dstZ : Float,
    baryX:Float,
    baryY:Float,
}

class TexturedQuadMesh{

	//TODO public var textureId ?
	public var x1(default,null): Float;
	public var y1(default,null): Float;
	public var x2(default,null): Float;
	public var y2(default,null): Float;
    public var u1(default,null): Float;
    public var v1(default,null): Float;
    public var u2(default,null): Float;
    public var v2(default,null): Float;
	public var refX(default,null): Float;
	public var refY(default,null): Float;

	public function new(meshData : TexturedQuadMeshData){
        x1 = meshData.x1;
        y1 = meshData.y1;
        x2 = meshData.x2;
        y2 = meshData.y2;
		u1 = meshData.u1;
		v1 = meshData.v1;
		u2 = meshData.u2;
		v2 = meshData.v2;
		refX = meshData.refX;
		refY = meshData.refY;
	}
}

class Frame{
	public var index(default, null) : Int;
	public var mesh(default, null) : TexturedQuadMesh; // could use type parameter
	public var scaleX(default, null) : Float;
	public var scaleY(default, null) : Float;

	public function new(index : Int, frameData : FrameData){
		this.index = index;
		//TODO if frameData.meshData == null
		this.mesh = new TexturedQuadMesh(frameData.meshData);
		if (Reflect.hasField(frameData,"scaleX")){
			this.scaleX = frameData.scaleX;	
		}else{
			this.scaleX = 1;
		}
		
		if (Reflect.hasField(frameData,"scaleY")){
			this.scaleY = frameData.scaleY;	
		}else{
			this.scaleY = 1;
		}
	}
}


class FrameAnimation{
	public var id(default, null) : String;
    var frames : Array<Frame>;

    public function new(id : String, frames : Array<FrameData>){
    	this.frames = new Array();
    	var i = 0;
        for (frame in frames){
            this.frames.push(new Frame(i,frame));
            i++;
        }
    }

    public function getFrame(elapsedTime : Float){
        if(elapsedTime==1){return frames[0];}
        else{
        var i=Std.int(elapsedTime%3);
    	return frames[i]; //TODO
        }
        
    }
}

class Sprite{
	public var id(default, null) : String;
	var animations : Map<String,FrameAnimation>;

	public function new(id : String, spriteData : SpriteData){
		this.animations = new Map();
		for (animationId in Reflect.fields(spriteData)){
			this.animations[animationId] = new FrameAnimation(animationId, Reflect.field(spriteData, animationId));
		}
	}

	public function getFrame(animationId : String, elapsedTime : Float){
		var animation = animations[animationId];
		if(animation != null){
			return animation.getFrame(elapsedTime);
		}
		return null;
	}
}

class SpriteLibrary{
	var _sprites : Map<String,Sprite>;

	public function new(){
		_sprites = new Map();
	}

	public function loadSprites(spriteSet : SpriteDataSet, textureAtlas : TextureAtlas){
		for(spriteId in Reflect.fields(spriteSet)){
			var spriteData : SpriteData = Reflect.field(spriteSet,spriteId);
			for (animationId in Reflect.fields(spriteData)){
				var animationData : AnimationData = Reflect.field(spriteData, animationId);
				for(frameData in animationData){
					var originalCutOut : CutOut = Reflect.field(textureAtlas.cutOuts,frameData.textureCutOut);
		            var uRatio = 1 / textureAtlas.width;
		            var vRatio = 1 / textureAtlas.height;
		            frameData.meshData = {
                        x1: originalCutOut.x1,
                        y1: originalCutOut.y1,
                        x2: originalCutOut.x2,
                        y2: originalCutOut.y2,
		            	u1: originalCutOut.x1 * uRatio,
		            	v1: originalCutOut.y1 * vRatio,
		            	u2: originalCutOut.x2 * uRatio,
		            	v2: originalCutOut.y2 * vRatio,
		            	refX: originalCutOut.refX,
		            	refY: originalCutOut.refY,
		            	//textureId : textureAtlas.bitmapId
		            };
				}
			}
			
            var sprite = new Sprite(spriteId, spriteData);
            _sprites[spriteId] = sprite;
        }
	}

	public function draw(buffer : glee.GPUBuffer<NormalTexturedProgram>, context : korrigan.TransformationContext, spriteId : String, animationName : String, elapsedTime : Float, x : Float, y : Float, z : Float, angle_z:Float, ?width : Float = 0, ?height : Float = 0, ?keepRatio : Bool = true) : Void{
		var placement = getTexturePlacement(context, spriteId, animationName, elapsedTime,x,y,z,angle_z,width,height,keepRatio);
        buffer.write_barycentre(placement.baryX, placement.baryY);
        buffer.write_barycentre(placement.baryX, placement.baryY);
        buffer.write_barycentre(placement.baryX, placement.baryY);
        buffer.write_barycentre(placement.baryX, placement.baryY);
        buffer.write_barycentre(placement.baryX, placement.baryY);
        buffer.write_barycentre(placement.baryX, placement.baryY);
                
		buffer.write_position(placement.dstX1, placement.dstY1, z);	
		buffer.write_position(placement.dstX3, placement.dstY3, z);
		buffer.write_position(placement.dstX2, placement.dstY2, z);
		buffer.write_position(placement.dstX4, placement.dstY4, z);
        buffer.write_position(placement.dstX2, placement.dstY2, z);
        buffer.write_position(placement.dstX3, placement.dstY3, z);
        
		
        buffer.write_alpha(context.alpha);
        buffer.write_alpha(context.alpha);
        buffer.write_alpha(context.alpha);
        buffer.write_alpha(context.alpha);
        buffer.write_alpha(context.alpha);
        buffer.write_alpha(context.alpha);

		
		buffer.write_texCoords(placement.srcX1, placement.srcY1);
		buffer.write_texCoords(placement.srcX1, placement.srcY2);
		buffer.write_texCoords(placement.srcX2, placement.srcY1);
		buffer.write_texCoords(placement.srcX2, placement.srcY2);
        buffer.write_texCoords(placement.srcX2, placement.srcY1);
        buffer.write_texCoords(placement.srcX1, placement.srcY2);
	}

	public function getTexturePlacement(context : korrigan.TransformationContext, spriteId : String, animationName : String, elapsedTime : Float, x : Float, y : Float, z : Float, angle_z:Float, ?width : Float = 0, ?height : Float = 0, ?keepRatio : Bool = true) : TexturePlacement{
		var sprite = _sprites[spriteId];
	    
	    var frame : Frame = null;
	    var error = false;
        //TODO always upload an error texture (in debug mode only ?)
        if (sprite == null) {
            trace("no sprite with id : " + spriteId);
            error = true;
        }else{
            frame = sprite.getFrame(animationName, elapsedTime);
            if (frame == null) {
                error = true;
                trace("no frame for animation : " + animationName);
            }
        }


        if(error){
            width = width == 0 ? 100 : width;
            height = height == 0 ? 100 : height; 
            return null;
//                {
//                    textureId : "error",
//                    srcX1 : 0,
//                    srcY1 : 0,
//                    srcX2 : 100,
//                    srcY2 : 100,
//                    dstX1 : x,
//                    dstY1 : y,
//                    dstZ : z,
//                    dstX2 : x + 100 * width /100,
//                    dstY2 : y + 100 * height /100
//                };
        }else{
            var mesh = frame.mesh;

            var meshWidth = mesh.x2 - mesh.x1;
            var meshHeight = mesh.y2 - mesh.y1;
            if(width == 0){
                width = meshWidth;
            }
            if(height == 0){
                height = meshHeight;
            }

            var scaleX = width / meshWidth;
            var scaleY = height / meshHeight;

            if(keepRatio){
                scaleX = scaleY = Math.min(scaleX,scaleY);
            }

            var offsetX = mesh.refX * frame.scaleX;
            var offsetY = mesh.refY * frame.scaleY;

            var targetX = x - (offsetX * scaleX);
            var targetY = y - (offsetY * scaleY);
            

            var rectX1 = targetX;
            var rectY1 = targetY;
            var rectX2 = targetX + meshWidth * scaleX;
            var rectY2 = targetY + meshHeight * scaleY;

            //Rotation before ortho:
            var cosZ = Math.cos(angle_z);
            var sinZ = Math.sin(angle_z);

            rectX1 = ((targetX-x)*cosZ - (targetY-y)*sinZ)+x;
            rectY1 = ((targetY-y)*cosZ + (targetX-x)*sinZ)+y;
            
            var vec = new Vec4();
            vec.x = rectX1;
            vec.y = rectY1;
            vec.z = z;
            vec.w = 1;
            context.transform(vec);
            var dstX1 = vec.x;
            var dstY1 = vec.y;

             //Rotation before ortho:
            rectX1 = targetX;
             rectY1 = targetY;
            rectX2 = ((targetX + meshWidth * scaleX-x)*cosZ - (targetY-y)*sinZ)+x;
            rectY1 = ((targetY-y)*cosZ + (targetX + meshWidth * scaleX-x)*sinZ)+y;

            vec.x = rectX2;
            vec.y = rectY1;
            vec.z = z;
            vec.w = 1;
            context.transform(vec);
            var dstX2 = vec.x;
            var dstY2 = vec.y;

            //Rotation before ortho:
             rectX2 =  targetX + meshWidth * scaleX;
             rectY1 = targetY;
            rectX1 = ((targetX-x)*cosZ - (targetY + meshHeight * scaleY-y)*sinZ)+x;
            rectY2 = ((targetY + meshHeight * scaleY-y)*cosZ + (targetX-x)*sinZ)+y;

            vec.x = rectX1;
            vec.y = rectY2;
            vec.z = z;
            vec.w = 1;
            context.transform(vec);
            var dstX3 = vec.x;
            var dstY3 = vec.y;

        
            //Rotation before ortho:
             rectX1 = targetX;
             rectY2 = targetY + meshHeight * scaleY;
            rectX2 = ((targetX + meshWidth * scaleX-x)*cosZ - (targetY + meshHeight * scaleY-y)*sinZ)+x;
            rectY2 = ((targetY + meshHeight * scaleY-y)*cosZ + (targetX + meshWidth * scaleX-x)*sinZ)+y;

            vec.x = rectX2;
            vec.y = rectY2;
            vec.z = z;
            vec.w = 1;
            context.transform(vec);
            var dstX4 = vec.x;
            var dstY4 = vec.y;
           

            var baryX=(dstX1+dstX2+dstX3+dstX4)/4;
            var baryY=(dstY1+dstY2+dstY3+dstY4)/4;

            return {
                //textureId :textureCutOut.textureId,
                srcX1 : mesh.u1,
                srcY1 : mesh.v1,
                srcX2 : mesh.u2,
                srcY2 : mesh.v2,
                dstX1 : dstX1,
                dstY1 : dstY1,
                dstX2 : dstX2,
                dstY2 : dstY2,
                dstX3 : dstX3,
                dstY3 : dstY3,
                dstX4 : dstX4,
                dstY4 : dstY4,
                dstZ : z,
                baryX:baryX,
                baryY:baryY,
           };
        }


	}

}