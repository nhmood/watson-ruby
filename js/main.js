// Remove preload class after page load
// Deals with blue links (transitions) on load problem
// Hide perl download info
$(window).load(function() {
	$("body").removeClass("preload");
	$("#download #perl").hide();
});

// Fade items sequentially
// When done with all, initiate first button click for GIF show
// Delay first click by some time using window.setTimeout
$('.fade').hide().each(function(i){
       $(this).delay(i * 1500).fadeIn(1500);
});

// On click for download section
// Toggle style from selected and show/hide section
$('#download p').click(function(){
	$('#download p').toggleClass('selected');
	$('#download #ruby').toggle('slow');
	$('#download #perl').toggle('slow');
});


// Initialize gallery
var gallery = new Gallery("#demo");
