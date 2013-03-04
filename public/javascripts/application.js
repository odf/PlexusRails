(function() {
  select_tab = function() {
    var link = jQuery(this);
    var ref = link.attr('href');
    console.log("Selected tab " + ref);
    var container = link.closest('.tabs-container', link);
    jQuery('> div', container).hide();
    jQuery('> div' + ref, container).show();
    jQuery('> ul a', container).removeClass('current-tab');
    link.addClass('current-tab');
    jQuery('> input:first', container).attr('value', ref);
    return false;
  }

  onload = function(context) {
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
      var related =
	jQuery(this).attr('data-pred') + jQuery(this).attr('data-succ');
      jQuery('.data-set').each(function() {
	if (related.indexOf(jQuery(this).attr('id')) >= 0)
	  jQuery(this).addClass('highlighted');
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
      //jQuery('> ul a', container).click(select_tab);
      jQuery('> ul li', container).click(function() {
        alert("Clicked a tab"); });
    });
  }

  fixPage = function() {
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
