(function($) {
  var methods, sel;
  sel = require('sel');
  $._select = sel.sel;
  methods = {
    find: function(s) {
      return $(s, this);
    },
    union: function(s, r) {
      return $(sel.union(this, sel.sel(s, r)));
    },
    difference: function(s, r) {
      return $(sel.difference(this, sel.sel(s, r)));
    },
    intersection: function(s, r) {
      return $(sel.intersection(this, sel.sel(s, r)));
    }
  };
  methods.and = methods.union;
  methods.not = methods.difference;
  methods.filter = methods.intersection;
  $.pseudos = sel.pseudos;
  return $.ender(methods, true);
})(ender);