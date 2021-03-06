package tri;

import glee.GPUBuffer;
import tri.SimpleProgram;

class Cube{
	var width : Float;
	var height : Float;
	var depth : Float;

	public function new(width : Float, height : Float, depth : Float){
		this.width = width;
		this.height = height;
		this.depth = depth;
	}

	public function write(buffer : GPUBuffer<SimpleProgram>){
		buffer.write_position(-width/2, height/2, -depth/2);	
		buffer.write_position(-width/2, -height/2, -depth/2);	
		buffer.write_position(width/2, -height/2, -depth/2);
		buffer.write_position(width/2, -height/2, -depth/2);	
		buffer.write_position(width/2, height/2, -depth/2);	
		buffer.write_position(-width/2, height/2, -depth/2);	

		buffer.write_position(-width/2, -height/2, depth/2);	
		buffer.write_position(-width/2, -height/2, -depth/2);	
		buffer.write_position(-width/2, height/2, -depth/2);
		buffer.write_position(-width/2, height/2, -depth/2);	
		buffer.write_position(-width/2, height/2, depth/2);	
		buffer.write_position(-width/2, -height/2, depth/2);	
  
  		buffer.write_position(width/2, -height/2, -depth/2);	
  		buffer.write_position(width/2, -height/2, depth/2);	
  		buffer.write_position(width/2, height/2, depth/2);	
  		buffer.write_position(width/2, height/2, depth/2);	
  		buffer.write_position(width/2, height/2, -depth/2);	
  		buffer.write_position(width/2, -height/2, -depth/2);	

		buffer.write_position(-width/2, -height/2, depth/2);	
  		buffer.write_position(-width/2, height/2, depth/2);	
  		buffer.write_position(width/2, height/2, depth/2);	
  		buffer.write_position(width/2, height/2, depth/2);	
  		buffer.write_position(width/2, -height/2, depth/2);	
  		buffer.write_position(-width/2, -height/2, depth/2);	
   
  		buffer.write_position(-width/2, height/2, -depth/2);	
  		buffer.write_position(width/2, height/2, -depth/2);	
  		buffer.write_position(width/2, height/2, depth/2);	
  		buffer.write_position(width/2, height/2, depth/2);	
  		buffer.write_position(-width/2, height/2, depth/2);	
  		buffer.write_position(-width/2, height/2, -depth/2);	
  
  		buffer.write_position(-width/2, -height/2, -depth/2);	
  		buffer.write_position(-width/2, -height/2, depth/2);	
  		buffer.write_position(width/2, -height/2, -depth/2);	
  		buffer.write_position(width/2, -height/2, -depth/2);	
  		buffer.write_position(-width/2, -height/2, depth/2);	
  		buffer.write_position(width/2, -height/2, depth/2);	
	}
}