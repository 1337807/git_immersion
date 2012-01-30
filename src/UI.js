function createCookie(name,value,days) {
  if (days) {
    var date = new Date();
    date.setTime(date.getTime()+(days*24*60*60*1000));
    var expires = "; expires="+date.toGMTString();
  }
  else var expires = "";
  document.cookie = name+"="+value+expires+"; path=/";
}

function readCookie(name) {
  var nameEQ = name + "=";
  var ca = document.cookie.split(';');
  for(var i=0;i < ca.length;i++) {
    var c = ca[i];
    while (c.charAt(0)==' ') c = c.substring(1,c.length);
    if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
  }
  return null;
}

function eraseCookie(name) { createCookie(name,'',-1); }


$(function() {
  // Bookmark
  var currentLabID           = $('body').attr('data-lab-id')
    , switchBookmarkOn       = function()  { $('#bookmark').addClass('active').animate({ top: 0, }, 100); }
    , switchBookmarkOff      = function()  { $('#bookmark').removeClass('active').animate({ top: -6, }, 100); }
    , navigateToNextPage     = function()  { $('#arrow_next').click(); }
    , navigateToPreviousPage = function()  { $('#arrow_previous').click(); }
    , followHREF             = function(e) { window.location = '/' + $(this).attr('href'); }
  ;


  if(readCookie(currentLabID)) { switchBookmarkOn(); }

  $('#index li').each(function(i, item){
    var item = $(item);
    console.log('LAB ID: ' + item.attr('data-lab-id'));
    if(readCookie(item.attr('data-lab-id'))) { item.addClass('bookmark'); }
  });

  $('#bookmark_link').on('click', function(e) {
    e.preventDefault();
    if($('#bookmark').hasClass('active')) {
      switchBookmarkOff();
      eraseCookie(currentLabID);
      $('#lab_' + currentLabID +'_link').removeClass('bookmark');
    } else {
      switchBookmarkOn();
      createCookie(currentLabID, '1', 365);
      $('#lab_' + currentLabID +'_link').addClass('bookmark');
    }
  });

  $('#show_bookmarks').on('click', function() {
    var bookmark = $(this);
    if(bookmark.hasClass('active')) {
      bookmark.removeClass('active')
              .animate({ top: -6, }, 100);

      $('#no_bookmarks').fadeOut(100);
      $('#index li').fadeIn(100);
    } else {
      bookmark.addClass('active')
              .animate({ top: 0, }, 100);

      $('#index li:not(.bookmark)').fadeOut(100);
      if(!$('#index .bookmark').length) {
        $('#no_bookmarks').fadeIn(200);
      }
    }
  });


  // Lab Index
  $('#table_of_contents_link').on('click', function(e) {
    e.preventDefault();
    $('#index').fadeToggle(200);
  });

  $('#index ul').hover(
    function() { $(this).addClass('hover'); },
    function() { $(this).removeClass('hover'); }
  );


  // Page nav key bindings
  $('#arrow_next, #arrow_previous').on('click', followHREF);
  $(document).click(function(e) {
    if (!$(e.target).closest('#table_of_contents_link, #index').length) {
      $('#index').fadeOut(100);
    }
  }).keyup(function(e) {
    if(e.keyCode == 27)                    { /* escape key */       $('#index').fadeOut(100); }
    if(e.keyCode == 76 || e.keyCode == 39) { /* l or right arrow */ navigateToNextPage(); }
    if(e.keyCode == 72 || e.keyCode == 37) { /* h or left arrow */  navigateToPreviousPage(); }
  });


  // Pre tag fixens
  $('#main_content .instructions').each(function(i, pre) {
    var lines = pre.innerHTML.split("\n")
        container = $('<div class="instructions">');

    $.each(lines, function(i, line) {
      $('<pre>').html(line).appendTo(container);
    });

    $(pre).replaceWith(container);
  });
});