// gifinfo.js
// GIFInfodotjs 
// nhmood @ [gooscode labs] - 2013
// This content is licensed under the MIT License
// See the file LICENSE for copying permission


// [todo] - Figure out cross domain GIFs and stuff for XMLHttpRequest()
//			Might be a browser related thing?


// Debug flag over entire file
var GIFINFODEBUG = 0;



function GIF(src){
	// Fill in gallery options or use defaults
	// src 	- Source of GIF file, has to be on same domain for now
	this.src = typeof(src) === "undefined" ? "" : src;

	// Container for raw image data from the XMLHttpRequest()
	this.rawData;
	
	// GIF Object components
	this.frameCount = 0;
	this.rawPtr = 0;
	this.ready = 0;

	// GIF Data components
	this.header;
	this.LSD = new LogicalScreenDescripor();
	this.images = new Array();

	// Debug flag for class console.log
	this.DEBUG = 1;


	// Run
	this.readGIF();
};

// GIF debug print, looks for global GIFINFODEBUG flag at top of this file
// If set, will print, else won't
// Easiest way to do scoped debug for just this file
GIF.prototype.log = function(e) {
	if (GIFINFODEBUG){
		console.log(e);
	}
};

function LogicalScreenDescripor(){
	this.screenWidth;			// Screen Width
	this.screenHeight;			// Screen height

	this.GCTflag;				// Whether custom GCT exists 
	this.GCTresolution;			// Resolution of custom GCT
	this.GCTsort;  				// Whether GCT values are sorted
	this.GCTsize;				// Size of custom GCT (bytes)

	this.GlobalColorTable;		// Array of GCT[r/g/b][0 -> (2 ^ GCTsize + 1)]

	this.backgroundColorIndex;	// Default BG color
	this.pixelAspectRatio;		// Custom pixel aspect ratio
};


function Frame() {
	this.AE = new ApplicationExtension();
	this.GCE = new GraphicsControlExtension();
	this.IMG = new GIFImage();
};


function ApplicationExtension() {
	this.identifier; 	// Identifier + Authentication code
	this.aData; 		// AE Data
						// data is already taken by JS
};


function GraphicsControlExtension() {
	this.reserved;			// Reserved bits
	this.disposalMethod;	// How to deal with data after display
	this.userInput;			// User input expected before continue
	this.transparentFlag;	// Whether transparency index is given
	this.delay = 0;			// Delay before next frame (in ms)
	this.transparentIndex;	// If encountered, pixel value is skipped
};


function GIFImage() {
	// These parameters DO NOT necessary have to match
	// those in the LSD
	this.cLeft;		// Left corner coord
	this.cTop;		// Top corner coord
	this.imgWidth;	// Width of image
	this.imgHeight;	// Height of image

	this.LCTFlag;	// Local Color Table flag
	this.interlace;	// If image is interlaced
	this.sort;		// Whether LCT is sorted
	this.reserved;	// Reserved bits
	this.LCTSize;	// Size of LCT

	this.LCT;		// Array of GCT[r/g/b][0 -> (2 ^ GCTsize + 1)]

	this.LZWminSize;	// LZW Minimum Size (used in decoding)
	this.imgData;		// Image data

};


GIF.prototype.readGIF = function(e) {
	GIF.prototype.log("Starting XMLHttpRequest of GIF");
	var req = new XMLHttpRequest();

	// Once data has been loaded, call the parser
	// Finally figured out what a closure is...
	// Use one so we have scope to populate the GIF.rawData field
	var self = this;
	req.onload = function(e){
		GIF.prototype.log("XMLHttpRequest Callback");
		// Store the response in a tmp var
		var arrayBuffer = this.response;
		// Load the data into a new Uint8Array, super convinient
		// because it breaks each array item into a byte!
		var uintArray = new Uint8Array(arrayBuffer);
		GIF.prototype.log(uintArray);
		// We don't want a Uint8Array though, it doesn't have all
		// the fancy methods of regular Array (like slice, pop, ext)
		// Don't feel like adding those methods to Uint8Array
		// Not the most efficient thing to do but oh well
		self.rawData = new Array();
		for (var i = 0; i < uintArray.length; i++){
			self.rawData.push(uintArray[i]);
		}
		self.parseGIF();
	};

	req.open("get", this.src, true);

	// Store data as arraybuffer, so it is super easy to deal with
	req.responseType = "arraybuffer";
	req.send();
	
};


GIF.prototype.parseGIF = function(e) {
	GIF.prototype.log("Starting GIF Parsing");

	this.readHeader();
	this.readLSD();

	// Add new frame to images[] array of Frames
	this.images.push(new Frame());	

	// Start reading GIF byte by byte to look for blocks
	// 59 == 0x3B which is the terminator block
	var rByte = this.readByte(1, false);
	while (rByte != 59){
		GIF.prototype.log("Frame: " + (this.frameCount + 1));
		// 0x21F9 == 8697 --> Graphics Control Extension
		// 0x2101 == 8449 --> Plain Text Extension
		// 0x21FF == 8703 --> Application Extension
		// 0x21FE == 8702 --> Comment Extension

		// If no Extension block is specified, we should have Image block 
		// 0x2C == 44--> Image separator, signals beginning of Image block

		// Look for extension block
		// 0x21 == 33
		if (rByte == 33){
			GIF.prototype.log("Found extension block 0x21");
			// Read next byte to igoure out which extension block
			rByte = this.readByte(1, false);

			// If Application Extension (0x21FF, 255)
			if (rByte == 255){
				GIF.prototype.log("Application Extension Block Detected");
				this.readAE();
				GIF.prototype.log("AE for frame " + (this.frameCount + 1) + " complete");
			}
			// Graphics Control Extension (0x21F9, 249)
			else if (rByte == 249){
				GIF.prototype.log("Graphics Extension Block Detected");
				this.readGCE();
				GIF.prototype.log("GCE for frame " + (this.frameCount + 1) + " complete");
			}
		}
		// If Image Separator (0x2c, 44) found
		else if (rByte == 44){
			GIF.prototype.log("Image Separator Block Detected");
			this.readIMG();

			// Increment frame count after frame has been processed
			// We add frames prior to filling so images[] is always ahead of frameCount by 1
			this.frameCount++;
			GIF.prototype.log("IMG for frame " + this.frameCount + " complete");
			
			// Add another Image to the image array
			this.images.push(new Frame());
		}

		// Read next byte to have data ready for the while check
		rByte = this.readByte(1, false);

	}

	// Once we leave the while loop (terminator block is found), set ready flag
	// This is so we can test for completion outside of this object
	this.ready = 1;

	GIF.prototype.log("GIF Parsing Complete");
};


GIF.prototype.getDuration = function(e) {
	GIF.prototype.log("Getting Total Duration of " + this.src);
	if (this.images.length == 0){
		throw("Doesn't seem like the GIF has been parsed yet");
	}

	var dur = 0;
	for (var i = 0; i < this.frameCount; i++){
		dur += this.images[i].GCE.delay;
	}

	// Duration obtained from GIF is in 1/100th of a second
	// Multiply return value by 10 to get it in ms (which is used for setTimeout)
	return (dur * 10);
};


GIF.prototype.readByte = function(bytes, isChar) {
	// Throw error for invalid byte sizes
	if (bytes <= 0){
		throw("Invalid byte size, please enter value greater than 1");
	}

	// Set isChar default in case of empty isChar
	var isChar = typeof(isChar) === "undefined" ? false : isChar;

	// If the user wants a string, create new temp array to store the string
	// If not, assign retVal to 0 (assign to number)
	// For consistency maybe use new Number()?
	var retVal = (isChar) ? new Array() : 0;

	// Using shift method was ridiculously slow, maybe because it allocates a new array
	// or maybe because it had to be called sequentially for each byte, either way
	// this is muuuuuch faster
	// Keep track of rawPtr which is current position in rawData, only slice out portions we need
	if (isChar){
		retVal.push(String.fromCharCode(this.rawData.slice(this.rawPtr, this.rawPtr + bytes)));
	}
	else {
		for (var i = 0; i < bytes; i++){
			retVal += this.rawData[this.rawPtr + i] << (8 * i);
		}
	}

	// Increment rawPtr after we read the bytes so we know where we are
	this.rawPtr += bytes;

	// If user requested string, join all the array elements into a single string
	if (isChar){
		GIF.prototype.log(retVal.join(''));
		return retVal.join('');
	}
	// Else just return the decimal value
	else {
		return retVal;
	}
}


GIF.prototype.readHeader = function(e) {
	// We can probably do this inline and not need a function call
	// but performance isn't really that much of an issue right now
	// and this way we can follow some standard and make this code modifyable 

	// Header is 6 bytes
	this.header = this.readByte(6, true);
	GIF.prototype.log(this.header);
};


GIF.prototype.readLSD = function(e) {
	// Width and Height are both 2 bytes
	this.LSD.screenWidth = this.readByte(2, false);
	this.LSD.screenHeight = this.readByte(2, false);


	// Next is a packed byte, more deets in dev/gifinfo.c
	// Packed byte with Global Color Table info
	// (MSB) Bit 8 -> GCT Flag (used or not used)
	//		 Bit 7 -> GCT Resolution (# of bits per R/G/B pixel)
	//		 Bit 6
	//		 Bit 5
	//		 Bit 4 -> GCT Sort (GCT is sorted or not)
	//		 Bit 3 -> GCT Size (# of bytes in color table, if flag is 1)
	//		 Bit 2
	//		 Bit 1
	
	var GCT_FLAG_BITS = 128; // 0x80
	var GCT_FLAG_SHIFT = 7;

	var GCT_RES_BITS = 112; // 0x70
	var GCT_RES_SHIFT = 4;

	var GCT_SORT_BITS = 8; // 0x08
	var GCT_SORT_SHIFT = 3;

	var GCT_SIZE_BITS = 7; // 0x07
	var GCT_SIZE_SHIFT = 0

	var packed = this.readByte(1, false);

	this.LSD.GCTflag = (packed & GCT_FLAG_BITS) >> GCT_FLAG_SHIFT; 
	this.LSD.GCTresolution = ((packed & GCT_RES_BITS) >> GCT_RES_SHIFT) + 1;
	this.LSD.GCTsort = (packed & GCT_SORT_BITS) >> GCT_SORT_SHIFT;
	this.LSD.GCTsize = (packed & GCT_SIZE_BITS) >> GCT_SIZE_SHIFT;

	// Background Color Index (1 byte)
	this.LSD.backgroundColorIndex = this.readByte(1, false);

	// Pixel Aspect Ratio (1 byte)
	this.LSD.pixelAspectRatio = this.readByte(1, false);

	// If GCT flag set, separate color table exists
	// Values are stored in GIF as consecutive RGB for each entry
	// Size of GCT is read from (2 ^ (GCTsize + 1)) aka 1 << (GCTsize + 1)
	if (this.LSD.GCTflag){
		GIF.prototype.log("GCT Flag set, separate Global Color Table Exists");
		this.LSD.GlobalColorTable = new Array();
		for (var i = 0; i < (1 << (this.LSD.GTCsize +1)); i++){
			var rgb = new Array();
			for (var j = 0; j < 3; j++){
				rgb.push(this.readByte(1, false));
			}
			this.LSD.GlobalColorTable.push(rgb);
		}
	}
	else {
		GIF.prototype.log("GCT Flag unset, no separate color table");
		this.LSD.GlobalColorTable = null;
	}

	GIF.prototype.log("LSD Complete");
	GIF.prototype.log(this.LSD);
};


GIF.prototype.readAE = function(e) {
	// Make local var that points to our current frame Image().AE
	var frame = this.images[this.frameCount].AE;

	
	// First byte will tell us how long hte Identifier and Authentication code is
	var rByte = this.readByte(1, false);

	frame.identifier = new String();
	// Should be 11 bytes and result should be NETSCAPE2.0
	frame.identifier = this.readByte(rByte, true);	

	// Next up is actual application data which is in data sub-block format
	// As usual, read dev/gifinfo.c for full details on all this stuff
	// tldr; First byte tells us how much space to allocate for next sub-block
	// Following bytes are actual data
	// Repeat until a first byte sub-block of 0 is found (terminate)

	frame.aData = new Array();
	rByte = this.readByte(1, false);
	while (rByte != 0){
		// First byte determines how much data we should read
		var tSize = this.readByte(1, false);
		
		// Read that much data and push it into 
		// Probably a better way to do this but we need to keep
		// the data in array form
		for (var i = 0; i < tSize; i++){
			frame.aData.push(this.readByte(1, false));
		}

		rByte = this.readByte(1, false);
	}

	GIF.prototype.log("Found sub-block of size 0, AE Complete");
	GIF.prototype.log(frame);	

};


GIF.prototype.readGCE = function(e) {
	// Make local var that points to our current frame Image().AE
	var frame = this.images[this.frameCount].GCE;
	
	// First byte is the Block size which tells us how many bytes
	// until the actual data, this should be 0x04 (4 bytes)
	var rByte = this.readByte(1, false);
	if (rByte != 4){
		GIF.prototype.log("Warning! GCE Block size SHOULD be 4 but isn't :(");
	}

	// Graphics Control Extension Packed byte
	// (MSB) Bit 8 -> Reserved 
	//		 Bit 7 
	//		 Bit 6
	//		 Bit 5 -> Disposal Method
	//		 Bit 4   
	//		 Bit 3  
	//		 Bit 2 -> User Input Flag
	//		 Bit 1 -> Transparent Color Flag
	
	// Read in single byte and mask off each field with corresponding defines	

	var GCE_RESERVED_BITS = 224; // 0xE0
	var GCE_RESERVED_SHIFT = 5;

	var GCE_DISPM_BITS = 28; // 0x1C
	var GCE_DISPM_SHIFT = 2;

	var GCE_USER_BITS = 2; // 0x02
	var GCE_USER_SHIFT = 1;

	var GCE_TRANS_BITS = 1; // 0x01
	var GCE_TRANS_SHIFT = 0;

	var packed = this.readByte(1, false);

	frame.reserved = (packed & GCE_RESERVED_BITS) >> GCE_RESERVED_SHIFT; 
	frame.disposalMethod = (packed & GCE_DISPM_BITS) >> GCE_DISPM_SHIFT;
	frame.userInput = (packed & GCE_USER_BITS) >> GCE_USER_SHIFT;
	frame.transparentFlag = (packed & GCE_TRANS_BITS) >> GCE_TRANS_SHIFT;


	// Next 2 bytes are the delay between frames (in ms)
	// This is the sweet spot for this gallery.js!
	frame.delay = this.readByte(2, false);
	
	// Finally, last byte is the Transparent Color Index
	frame.transparentIndex = this.readByte(1, false);

	// Last block is just a terminator block (00)
	// Make sure this happens just in case (plus we need to flush it out 
	// of our byte array)
	rByte = this.readByte(1, false);
	if (rByte != 0x00){
		GIF.prototype.log("Warning! Terminator block for GCE is not 0x00");
	}
	GIF.prototype.log("GCE Complete");
	GIF.prototype.log(frame);	
};


GIF.prototype.readIMG = function(e) {
	// Make local var that points to our current frame Image().AE
	var frame = this.images[this.frameCount].IMG;

	// First four items are dimensions of current frame image
	// All of them are 2 bytes
	frame.cLeft = this.readByte(2, false);
	frame.cTop  = this.readByte(2, false);
	frame.imgWidth = this.readByte(2, false);
	frame.imgHeight = this.readByte(2, false);



	// Next we have a packed byte
	// Image Packed byte
	// (MSB) Bit 8 -> Local Color Table Flag 
	//		 Bit 7 -> Interlace Flag 
	//		 Bit 6 -> Sort Flag
	//		 Bit 5 -> Reserved
	//		 Bit 4   
	//		 Bit 3 -> Size of Local Color Table 
	//		 Bit 2 
	//		 Bit 1 
	
	// Read in single byte and mask off each field with corresponding defines

	var IMG_FLAG_BITS = 128; // 0x80
	var IMG_FLAG_SHIFT = 7;

	var IMG_INTERLACE_BITS = 40; // 0x40
	var IMG_INTERLACE_SHIFT = 6;

	var IMG_SORT_BITS = 32; // 0x20
	var IMG_SORT_SHIFT = 5

	var IMG_RESERVED_BITS = 24; // 0x18
	var IMG_RESERVED_SHIFT = 3;

	var IMG_LCTSIZE_BITS = 7; // 0x07
	var IMG_LCTSIZE_SHIFT = 0;
	
	var packed = this.readByte(1, false);

	
	frame.LCTFlag = (packed & IMG_FLAG_BITS) >> IMG_FLAG_SHIFT;
	frame.interlace = (packed & IMG_INTERLACE_BITS) >> IMG_INTERLACE_SHIFT;
	frame.sort = (packed & IMG_SORT_BITS) >> IMG_SORT_SHIFT;
	frame.reserved = (packed & IMG_RESERVED_BITS) >> IMG_RESERVED_SHIFT;
	frame.LCTSize = (packed & IMG_LCTSIZE_BITS) >> IMG_LCTSIZE_SHIFT;


	// If LCT flag is enabled, we have to grab the Local Color Table
	if (frame.LCTFlag){
		GIF.prototype.log("LCT Flag set, separate color table exists");

		frame.LCT = new Array();
		for (var i = 0; i < (1 << (frame.LCTSize +1)); i++){
			var rgb = new Array();
			for (var j = 0; j < 3; j++){
				rgb.push(this.readByte(1, false));
			}
			frame.LCT.push(rgb);
		}
	}
	else {
		GIF.prototype.log("LCT Flag unset, no separate color table");
		frame.LCT = null;
	}

	
	// Finally, the imaga data, too bad we don't use it
	// LZW encoded, we won't decode
	// Represented in data sub-blocks (like AE)
	
	// First byte is LZW Minimum Code Size, used for decoding	
	frame.LZWminSize = this.readByte(1, false);
	frame.imgData = new Array();

	GIF.prototype.log("Parsing data sub-blocks for IMG");
	rByte = this.readByte(1, false);
	var sbc = 0;
	while (rByte != 0){
		// Store latest byte as size to grab
		var tSize = rByte;	
		
		// Read that much data and push it into 
		// Probably a better way to do this but we need to keep
		// the data in array form
		for (var i = 0; i < tSize; i++){
			frame.imgData.push(this.readByte(1, false));
		}

		// Read next byte after data block
		rByte = this.readByte(1, false);
	}
	
	GIF.prototype.log("Found sub-block of size 0. IMG Complete");
	GIF.prototype.log(frame);

};