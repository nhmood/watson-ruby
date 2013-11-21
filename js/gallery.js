// gallery.js
// gallerydotjs 
// nhmood @ [gooscode labs] - 2013
// This content is licensed under the MIT License
// See the file LICENSE for copying permission


// [todo] - Find a better name for this project ASAP
// [todo] - Convert options for gallery to this format, really nice
//			https://github.com/Leimi/drawingboard.js 
// [todo] - Add type checks for input opts

function Gallery(dID, args){
	// Fill in gallery options or use defaults
	// dID 			- div ID associated with this gallery
	// imgDelay 	- Default delay for an image (nonGIF)
	// pageDelay 	- Delay (after page load) before images start to cycle
	// autoCycle 	- Whether to auto cycle through images 

	this.dID = typeof(dID) === "undefined" ? "#gallery" : dID;

	// Catch empty args first 
	if (typeof(args) === "undefined"){
		this.imgDelay  = 10;  
		this.pageDelay = 10;
		this.autoCycle = true; 
	}
	
	// Catch any other empty parameter
	// Need to figure out if there is a object/hash merge like in Ruby
	else {
		this.imgDelay  = typeof(args.imgDelay)  === "undefined" ? 10   : parseInt(args.imgDelay);
		this.pageDelay = typeof(args.pageDelay) === "undefined" ? 10   : parseInt(args.imgDelay);
		this.autoCycle = typeof(args.autoCycle) === "undefined" ? true : args.autoCycle;
	}


	// Gallery data members
	// currentImage - Index of image that gallery is currently focused on
	// images[] - Array of Image() objects associated with this gallery
	// starterImage - Starter image for gallery
	// timerID - timerID for setTimeout calls 
	// displayReady - flag to indicate that all GIFs have been loaded
	// displayStarted - flag to indicate that pageDelay has passed and gallery is in progress
	this.currentImage = 0;
	this.images = new Array();
	this.starterImage = null;
	this.timerID = 0;
	this.displayReady = 0;
	this.displayStarted = 0;
	
	// Run
	this.getImages(this);
	this.initGallery(this);
	this.processImages(this);
};


Gallery.prototype.Image = function(gallery, src, text, imgDelay){
	// Fill in Image options or use defaults
	// I think "this" will refer to this Image? This JS scoping is confusing...
	this.src  = typeof(src) === "undefined" ? "" : src;
	this.text = typeof(text) === "undefined" ? "" : text;

	// Regex for .gif at END of src
	// If we can't find it, don't care what it is, not a GIF
	this.type = (this.src.match(/.gif$/) != null ) ? "GIF" : "IMG";
};


Gallery.prototype.getImages = function(gallery) {
	// Grab all images from the div associated with this Gallery
	// Populate our images Array with corresponding Image objects for each
	// Call remove() on each (real) image element we find to clean up page

	// If we find an image with the alt text of "starter" this is our starter image
	// Store this in the this.starterImage var but don't add this to our images[]

	$(gallery.dID + ' img').each( function(e) {
		this.remove();
		if ($(this).attr('alt').toLowerCase() == 'starter'){
			gallery.starterImage = new gallery.Image(gallery, $(this).attr('src'), $(this).attr('alt'), gallery.imgDelay);
		}
		else {
			var img = new gallery.Image(gallery, $(this).attr('src'), $(this).attr('alt'), gallery.imgDelay);
			gallery.images.push(img);
		}
	});
};


Gallery.prototype.initGallery = function(gallery){
	// This should be called AFTER getImages such that we have the necessary images
	// and they have been removed from the DOM
	// Add single demo image to the DOM
	if (gallery.starterImage != null){
		$(gallery.dID + ' #images').append("<img src=" + gallery.starterImage.src + "></img>");
	}
	else {
		// Built in starter image
		$(gallery.dID + ' #images').append("<img src=" + defStarter + "></img>");
	}

	// Add appropriate # of buttons
	for (var i = 0; i < gallery.images.length; i++){
		$(gallery.dID + ' #buttons').append("<div class=\"demobutton\"></div>");
	}

	// jQuery button onClick setup
	$(gallery.dID + ' .demobutton').click( function(e){
		// Get which image button we are on
		var i = $(this).index();

		// Don't register clicks unless all images have been processed
		if (gallery.displayReady >= gallery.images.length){
			// [todo] - Apply default css style instead of manual
			// Change all buttons to white then button for this image to gray
			$(gallery.dID + ' .demobutton').css('background', '#ffffff');
			$(this).css('background', '#323232');

			// Fade out the current image and replace with new image
			$(gallery.dID + ' #images img').fadeOut('normal', function(e){
				$(this).attr('src', gallery.images[i].src);
				$(this).fadeIn('normal');
			});

			// Fade out current text and replace with corresponding new image text
			$(gallery.dID + ' #title').fadeOut('normal', function(e){
				$(this).text(gallery.images[i].text);
				$(this).fadeIn('normal');
			});

			// Unless this.autoCycle is set to 0, make automatic slideshow with setTimeout
			// Clear previous timeouts (to accomodate for new clicks)
			// Set new timeout based on images[i].delay values
			if (gallery.autoCycle){
				window.clearTimeout(gallery.timerID);
				gallery.timerID = window.setTimeout(gallery.cycleImages, gallery.images[i].delay, gallery);
			}
		}
	});

	// setTimeout timing gets messed up on inactive tabs (at least in Chrome)
	// This is an attempt to reduce CPU load and other things while inactive
	// But this totally breaks our timing...so to fix this, if we leave and 
	// refocus on page, reset the current image animation from the beginning
	// Only perform this once first image has been loaded
	// Not the most ideal solution, but it's a solution lol
	$(window).focus(function(){
		// Perform only when gallery is in progrses
		if (gallery.displayStarted){
			// Really shouldn't be messing with the image index but oh well
			// If the currentImage is 0, set it to the last image (length - 1), else just subtract 1
			gallery.currentImage = (gallery.currentImage == 0) ? gallery.images.length - 1 : gallery.currentImage - 1; 
			gallery.cycleImages(gallery);
		}
	});

};


Gallery.prototype.processImages = function(gallery){
	for (var i = 0; i < gallery.images.length; i++) {
		// Check to make sure that first its a GIF and also we want to auto cycle
		// This causes a bunch of potentially unnecessary checks but I'd rather keep the code clean
		// and do the checks down here than have a if condition elsewhere
		if (gallery.images[i].type == "GIF" && gallery.autoCycle){ 
			// Create new GIF with given img src
			// This will begin magic, aka processing the GIF for duration and stuff
			var curGIF = new GIF(gallery.images[i].src);

			// Call the GIF checker that will determine whether the delay has been
			// determined or not
			// Pass the current gallery, THIS image, and the GIF object we just created
			this.checkGIF(gallery, gallery.images[i], curGIF);
		}
		else {
			// If neither, just set to default
			gallery.images[i].delay = gallery.imgDelay;
		}
	}
};


Gallery.prototype.checkGIF = function(gallery, curImage, curGIF){
	// Look for the ready flag in curGIF (GIF object associated with this Image)
	if (!curGIF.ready){
		// If the GIF isn't ready yet, set a timeout to run this function again
		// Pass THIS image and corresponding GIF, along with the gallery
		// Timeout time is 50ms, can play around with this but fine for now
		console.log("GIF Status: Not ready");
		setTimeout(gallery.checkGIF, 50, gallery, curImage, curGIF);
		return;
	}
	// If GIF is ready, get the duration from the GIF and run startCycle()
	else {
		console.log("GIF Status: Ready");
		curImage.delay = curGIF.getDuration();
		console.log("Image: " + curImage.src + " done");
		gallery.startCycle(gallery);
	}
};


Gallery.prototype.startCycle = function(gallery){
	// Increment displayReady everytime this function gets called
	// This function gets called everytime one of the GIFs is ready
	gallery.displayReady++;

	// If displayReady is less than the number of total GIFs we have, not ready yet
	if (gallery.displayReady < gallery.images.length){
		console.log("Not all GIFs ready yet");
	}
	// Else, go ahead and start the cycling process
	else {
		// Initialize first setTimeout to correspond to pageDelay
		// Set gallery.currentImage to -1 so that when we hit cycleImages it gets pushed to 0
		// Not the cleanest but it works for now
		console.log("All GIFs complete, beginning cycle");
		gallery.displayStarted = 1;
		gallery.currentImage = -1;
		gallery.timerID = window.setTimeout(gallery.cycleImages, gallery.pageDelay * 1000, gallery);
	}

};


Gallery.prototype.cycleImages = function(gallery){
	// Increment currentImage before using value for click, so we have a consistent button index
	// Do some modding so that we have a circular (around images.length) currentImage
	// Trigger a click on the child button associated with the index passed
	gallery.currentImage = (gallery.currentImage + 1 ) % gallery.images.length;
	$(gallery.dID + ' .demobutton:nth-child(' + ( ( gallery.currentImage ) + 1) + ')').trigger('click');
};





// Taken from http://www.acecrane.com/
// Still haven't explicitly asked for permission...
// Not sure if I should include this as a Gallery.prototype.defStarter or just have it
// be a global var?
// Also not sure how efficient it is to have this GIF here as a Base64...
defStarter = "data:image/gif;base64,R0lGODlh9AEsAcQAAP////v7+/Pz8+/v7+vr6+fn5+Pj49/f39vb" + 
		 	 "29fX19LS0s7OzsrKysbGxrKysq6urqampqKiop6enpaWlpKSko6Ojv4BAgAAAAAAAAAAAAAAAA" +
		 	 "AAAAAAAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQFCgAWACwAAAAA9AEsAQAF/yAg" +
		 	 "jmRpnmiqrmzrvnAsz3Rt33iu73zv/8CgcEgsGo/IpHLJbDqf0Kh0Sq1ar9isdsvter/gsHhMLp" +
		 	 "vP6LR6zW673/C4fE6v2+/4vH7P7/v/gIGCg4SFhoeIiYqLjI2Oj5CRkpOUlZaXmJmam5ydnp+g" + 
		 	 "oaKjpKWmp6ipqqusra6vsLGys7S1tre4ubq7vL2+v8DBwsPExcbHyMnKy8zNzs/Q0dLT1NXW19" +
		 	 "jZ2tvc3d7f4OHi4+Tl5ufo6err7O3u7/Dx8vP09fb3+Pn6+/z9/v8AAwocSLCgwYMIEypcyLCh" +
		 	 "w4cQI0qcSLGixYsYM2rcyLGjx48gQ4ocSbKkyZMoU/+qXMmypcuXMGPKnEmzps2bOHPq3Mmzp8" +
		 	 "+fQIMKHUq0qNGjSJMqXcq0qdOnUKNKnUq1qtWrWLNq3cq1q9evYMOKHUu2rNmzaNOqXcu2rdu3" +
		 	 "cOPKnUu3rt27ePPq3cu3r9+/gAMLHky4sOHDiBMrXsy4sePH+QQUQKBgAYAJERwwMAD5EgEEDE" +
		 	 "KHBlChdOkHCgJ0jjQAtGjRpE2bdnBgtSMCCl6/ji27tAQFthkt0L27t2wKwRMRsEwctnHTABYQ" +
		 	 "SF5oQG4GAF4nMDBAtYADDSDIzs5AwQDqg1yPLl8ARYAFEiqQD40AfSACxAGcV1Gb+HT7fqgXmg" +
		 	 "ICtCDAdaLVByD/HwIQ154LBRBX4IJ6RKhdDAno9iCFeAi4WQwG6KYgh3cgGNp+LwygG3Ak3jHc" +
		 	 "a6rBEIBulrVo4zovihbjCzO+VuONc5jIAIouqPgai0DK4SFnMIT42ohJwmGhaAlgqGGUcjR4JY" +
		 	 "QSYqnkihOucKCIXsqBn276rXCef2V+CRt7KRSQ23wMQNmmG9atRyV3qgUwgAEZvlkekXe6sRyd" +
		 	 "aDY3mnSF0pFjfooy8GOjZgopKHEK/EfpHK01hyh9hG5qpoeIIqCpqHdIRpllCyiAQAFhoirrrL" +
		 	 "TWauutuOaq66689urrr8AGK+ywxBZr7LHIJqvsssw26+yz0EYr7bTUVmvthrXYZqvtttx26+23" +
		 	 "4IYr7rjklmvuueimq+667Lbr7rvwxivvvPTWa++9+Oar77789uvvvwAHLPDABBds8MEIJ6zwwg" +
		 	 "w37PDDEEcs8cQUV2zxxRhnrPHGHHfs8ccghyzyyCSXbPLJKKes8sost+zyyzDHLPPMNNds8804" +
		 	 "56zzzjz37PPPzoQAACH5BAUKABYALPsAhwAPAA8AAAVM4KIghWCdaMqsK0KkKssiA2zJsvLG+L" +
		 	 "rAPZaFokAFBoaEzFKpSA62goLBbFYcNkvNai3aDhJu5ZG1LMQVQxkipmYbYmz2II6UBeJJCAAh" +
		 	 "+QQFCgAWACwBAYwACQAVAAAFS6AlWgsxjgyjDGeaIqibmoIiM7BV3IwgJreCyHDLDW4KUeC2OD" +
		 	 "lFgopUOhEdptKIqIGtOESQLoPUrRgOku5DVE6yp9+TVHJ4UtyWEAAh+QQFCgAWACz7AJcADwAP" +
		 	 "AAAFTKAljmLAnOdCkgN6KutouAwSiwld3AXNCDGBgmZbHSw+wmohqSBRRcGhAalYna+B6Mq1Wh" +
		 	 "bKbfdKWY2tEhjp7DiauQ91bBJxMAy3UQgAIfkEBQoAFgAs8ACdABUACQAABUmgJVrHaJrDKVbSo" +
		 	 "o6FwpxVXUHNIVjBYCSM4GxlK1YswmTQQjEWkUrhQiFx1qBRBYHksGKTiNRI8TB+GYjty8BwRCaW" +
		 	 "KaKwM4UAACH5BAUKABYALOsAlwAPAA8AAAVO4FSNo2Cd6BmR45GmDls1L8rIUH0acrXolodM4qo" +
		 	 "pepaBLkayMBSF2kEycjKuCcMggFJQrNfw9bUQm18EhTlcGyDWDCDhLQaeBAWEYhECACH5BAUKAB" +
		 	 "YALOsAjAAJABUAAAVLoCUqlGhah1RVp+Wsq6nAsPjQlXQYeLVYDBxE9KI1RBHcQTTBCVrQBWM6D" +
		 	 "Yyo04EIgWUYRIVuQiToMgrbruJJMJu41NNAMYUSfqYQACH5BAUKABYALOsAhwAPAA8AAAVMoCWO" +
		 	 "pME40USSylO972odDmyvimTfJLXzFsLC8oOJBgoGgwiDNA4CEUKpJEqGJAKVOpNNt4roSrBVFmS" +
		 	 "WQjmBtnyphnZyO2gvyoF2CAA7";
