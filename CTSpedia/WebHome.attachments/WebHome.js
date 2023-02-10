$(function() {
  $('.patternTop').hide();  // hide breadcrumbs
  $('.foswikiTopic div li:nth-child(even)').addClass('alt');
  $('.foswikiTopic li a').each(function() { $(this).attr('title', $(this).text()); });
  $('.foswikiTopic li').click(function() { $(this).find('a').click(); });
});
