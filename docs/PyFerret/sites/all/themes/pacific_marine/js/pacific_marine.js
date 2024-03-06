(function($) {
  $(document).ready(function() {
    
    // Get window width initially and on resize.
    var wi = $(window).width();
  
    // Define a value for a breakpoint for functions to take advantage of.
    var breakPoint = 740;
  
    // Define the contents of the mobile menu button.
    var menuButton = $('<img src="/Ferret/sites/all/themes/pacific_marine/images/menu.jpg" alt="Mobile Menu Button" id="hamburger" />');
  
    // Define the contents of the mobile menu button.
    var searchButton = $('<img src="/Ferret/sites/all/themes/pacific_marine/images/search.jpg" alt="Mobile Search Button" id="search" />');

    // Remove clearfix from fields with inline labels and add appropriate css inline.
    $('.field-label-inline').removeClass('clearfix').css('width','100%').find('.field-label, .field-items').css('float','none');

    // Mobile-only behaviors.
    if(wi < breakPoint) {

      var branding = $('#region-branding');
      var menu = $('#block-system-main-menu');
      var search = $('#block-search-form');

      // Make the menu and search box mobile-friendly.
      branding.before(searchButton);
      branding.before(menuButton);

      // Make menu and search open when clicking their buttons.
      menuButton.click(function() {menu.slideToggle('fast').toggleClass('open')});
      searchButton.click(function() {search.slideToggle('fast').toggleClass('open')});
      
      // Handle sub-menus for mobile.
      menu.find('li.expanded').click(function(e) {
        // Do nothing if it's already open.
  	    if ($(this).hasClass('open')) {
    		  return;
  	    } else {
  	      // Expand the sub-menu when the parent link is clicked.
  	      e.preventDefault();
  	      $(this).toggleClass('open').find('ul.menu').slideDown('fast');
        }
      });
      
      // Make the hidden h2 for tabs visible and clickable to show tab options for content editors.
      $('.tabs h2.element-invisible').text('Editor options').click(function(){$('ul.tabs.primary').toggle()});

    } 

    // Tablet and desktop behaviors (width > breakPoint).
    else {

      // Fix a bug in Omega that adds contextual links to a higher level in the markup than it needs to be.
      $('.front #zone-postscript .contextual-links-region').removeClass('contextual-links-region');
      
    }
  
  });
})(jQuery);