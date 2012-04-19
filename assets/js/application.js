jQuery(function($) {
        $('.carousel .item').first().addClass('active');
	$('.dropdown-toggle').dropdown();
        $('.carousel').carousel( { interval: false } );

	$('.carousel').bind('slide', function () {
		resize_image_info();
	});

	resize_image_info();

	function resize_image_info() {
		$('.carousel-caption').each(function () {
			itemWidth = $(this).siblings('img').width();
			$(this).css('max-width', (itemWidth-30)+'px');
		});
	}

	$(window).resize(function () {
		resize_image_info();
	});
});
