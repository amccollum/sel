(function($) {
  var create, methods, nodeMap, sel, tagPattern;
  sel = require('sel');
  nodeMap = {
    thead: 'table',
    tbody: 'table',
    tfoot: 'table',
    tr: 'tbody',
    th: 'tr',
    td: 'tr',
    fieldset: 'form',
    option: 'select'
  };
  tagPattern = /^\s*<([^\s>]+)/;
  create = function(html, root) {
    var el, parent, tag, _i, _len, _ref, _results;
    tag = tagPattern.exec(html)[1];
    parent = (root || document).createElement(nodeMap[tag] || 'div');
    parent.innerHTML = html;
    _ref = parent.childNodes;
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      el = _ref[_i];
      if (el.nodeType === 1) {
        _results.push(el);
      }
    }
    return _results;
  };
  $._select = function(s, r) {
    if (/^\s*</.test(s)) {
      return create(s, r);
    } else {
      return sel.sel(s, r);
    }
  };
  methods = {
    find: function(s) {
      return sel.sel(s, this);
    },
    union: function(s, r) {
      return sel.union(this, $(s, r));
    },
    difference: function(s, r) {
      return sel.difference(this, $(s, r));
    },
    intersection: function(s, r) {
      return sel.intersection(this, $(s, r));
    }
  };
  methods.and = methods.union;
  methods.not = methods.difference;
  methods.filter = methods.intersection;
  $.pseudos = sel.pseudos;
  return $.ender(methods, true);
})(ender);