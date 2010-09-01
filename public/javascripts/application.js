(function() {
  function select_tab() {
    var link = jQuery(this);
    var ref = link.attr('href');
    var container = link.closest('.tabs-container', link);
    jQuery('> div', container).hide();
    jQuery('> div' + ref, container).show();
    jQuery('> ul a', container).removeClass('current-tab');
    link.addClass('current-tab');
    jQuery('> input:first', container).attr('value', ref);
    return false;
  }

  function onload(context) {
    fixPage();

    // -- some text cosmetics:
    jQuery('.properties dfn,.attachments dfn', context).each(function(i) {
      var s = jQuery(this).text();
      if (s[s.length - 1] != ':') s = s + ':';
      jQuery(this).text(s);
    });
    jQuery('.action-links a', context).each(function(i) {
      var s = jQuery(this).text();
      if (s[0] != '[') s = '[' + s;
      if (s[s.length - 1] != ']') s = s + ']';
      jQuery(this).text(s);
    });

    // -- highlights predecessors and successors of a data set on hover
    jQuery('.data-set', context).hover(function() {
      var related = jQuery(this).find(".predecessors,.successors").text();
      jQuery('.data-set').each(function() {
	var item = jQuery(this);
	if (related.indexOf(item.attr('id')) >= 0) item.addClass('highlighted');
      });
      return false;
    }, function() {
      jQuery('.data-set').removeClass('highlighted');
    });

    // -- handles tabs
    jQuery('.tabs-container', context).each(function() {
      var container = jQuery(this);
      jQuery('> ul', container).show();
      jQuery('> div', container).hide();
      jQuery('> input:first', container).attr('name', 'active-tab');
      var current = container.find('> ul a.current-tab:first');
      if (current.length > 0)
	current.each(select_tab);
      else
	container.find('> ul a:first').each(select_tab);
      jQuery('> ul a', container)
	.each(function() {
	  var link = jQuery(this);
	  var container = link.closest('.tabs-container', link);
	  var err = jQuery('> div' + link.attr('href') + ' .error', container);
	  if (err.size() > 0) link.addClass("with-error");
	})
	.click(function() { jQuery('#flash_notice', context).hide(); })
	.click(select_tab);
    });

    // -- make mouseovers on data sets appear more smoothly
    jQuery('.data-set-header .data-set-popup', context)
      .hide().addClass('captured');
    jQuery('.data-set-header', context).hover(function() {
      jQuery(this).find('.data-set-popup').each(function() {
	jQuery(this).addClass('waiting');
	setTimeout(function() {
	  jQuery('.data-set-popup.waiting')
	    .stop(true, true).slideDown('fast').removeClass('waiting');
	}, 500);
      });
    }, function() {
      jQuery(this).find('.data-set-popup')
	.stop(true, true).slideUp('fast').removeClass('waiting');
    });
  }

  function fixPage() {
    jQuery('table.zebra')
      .find('tr:nth-child(odd)').removeClass('odd').addClass('even').end()
      .find('tr:nth-child(even)').removeClass('even').addClass('odd');
  }

  jQuery(document).ready(function() {
    onload(document);

    // -- enable ajax templating via jquery.djtch.js
    jQuery.djtch.setup({
      preUpdateHook:  onload,
      postUpdateHook: fixPage
    });
    jQuery(document).djtchEnable();
  });
})();
