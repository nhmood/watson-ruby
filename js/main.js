// Remove preload class after page load
// Deals with blue links (transitions) on load problem
// Hide perl download info
$(window).load(function() {
	$("body").removeClass("preload");
	$("#download #perl").hide();
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
