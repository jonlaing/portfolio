jQuery(function($) {

	$('.carousel .item').first().addClass('active');
	$('.dropdown-toggle').dropdown();
	$('.carousel').carousel( { pause: true, interval: 5000000000 } );

	$('.carousel').bind('slide', function () {
		resize_image_info();
	});

	$(window).resize(function () {
		resize_image_info();
	});

	$('.carousel .active').each(function () {
		width = $(this).find('img').width();
		$(this).find('.carousel-caption').css('max-width', (width-30)+'px');
	});

	function resize_image_info() {
		$('.carousel-caption').each(function () {
			itemWidth = $(this).siblings('img').width();
			$(this).css('max-width', (itemWidth-30)+'px');
		});
	}
});
