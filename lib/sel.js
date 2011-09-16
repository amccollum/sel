var attrGroups, attrPattern, checkNth, checkNthExpr, children, comparePosition, contains, difference, elCmp, evaluate, filterAttr, filterClasses, filterPseudo, filterTag, find, findClasses, findId, findTag, html, intersect, memoRegExp, nextElementSibling, normalizeRoots, nthPattern, parse, parseChunk, parseSimple, pseudoGroups, pseudoPattern, sel, select, selectorGroups, selectorPattern, uniq, _hasDuplicates;
sel = typeof exports !== "undefined" && exports !== null ? exports : (this.sel = {});
/* util.coffee */
html = document.documentElement;
memoRegExp = function(r) {
  return memoRegExp.cache[r] || (memoRegExp.cache[r] = new RegExp(r));
};
memoRegExp.cache = {};
_hasDuplicates = null;
elCmp = function(a, b) {
  if (!a) {
    return -1;
  }
  if (!b) {
    return 1;
  }
  if (a === b) {
    _hasDuplicates = true;
    return 0;
  }
  if (comparePosition(a, b) & 4) {
    return -1;
  } else {
    return 1;
  }
};
uniq = function(arr) {
  var i;
  _hasDuplicates = false;
  arr.sort(elCmp);
  if (_hasDuplicates) {
    i = arr.length - 1;
    while (i) {
      if (arr[i] === arr[i - 1]) {
        arr.splice(i, 1);
      } else {
        i--;
      }
    }
  }
  return arr;
};
intersect = function(a, b) {
  var arr, i, j;
  arr = [];
  i = 0;
  j = 0;
  while (i < a.length && j < b.length) {
    switch (elCmp(a[i], b[j])) {
      case -1:
        i++;
        break;
      case 1:
        j++;
        break;
      case 0:
        arr.push(a[i++]);
    }
  }
  return arr;
};
difference = function(a, b) {
  var arr, i, j;
  arr = [];
  i = 0;
  j = 0;
  while (i < a.length) {
    if (j >= b.length) {
      arr.push(a[i++]);
    } else {
      switch (elCmp(a[i], b[j])) {
        case -1:
          arr.push(a[i++]);
          break;
        case 1:
          j++;
          break;
        case 0:
          i++;
      }
    }
  }
  return arr;
};
contains = html.compareDocumentPosition != null ? function(a, b) {
  return (a.compareDocumentPosition(b) & 16) === 16;
} : html.contains != null ? function(a, b) {
  if (a === document || a === window) {
    a = html;
  }
  return a !== b && a.contains(b);
} : function(a, b) {
  while (b = b.parentNode) {
    if (a === b) {
      return true;
    }
  }
  return false;
};
comparePosition = html.compareDocumentPosition ? function(a, b) {
  return a.compareDocumentPosition(b);
} : function(a, b) {
  return (a !== b && a.contains(b) && 16) + (a !== b && b.contains(a) && 8) + (a.sourceIndex < 0 || b.sourceIndex < 0 ? 1 : (a.sourceIndex < b.sourceIndex && 4) + (a.sourceIndex > b.sourceIndex && 2));
};
nextElementSibling = html.nextElementSibling ? function(el) {
  return el.nextElementSibling;
} : function(el) {
  while ((el = el.nextSibling)) {
    if (el.nodeType === 1) {
      return el;
    }
  }
  return null;
};
/* find.coffee */
find = function(roots, m) {
  var attr, cls, els, pseudo, _i, _j, _k, _l, _len, _len2, _len3, _len4, _ref, _ref2, _ref3, _ref4;
  if (m.id) {
    els = findId(roots, m.id);
    if (m.tag) {
      els = filterTag(els, m.tag);
    }
    if (m.classes) {
      _ref = m.classes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        cls = _ref[_i];
        els = filterAttr(els, 'class', '~=', cls);
      }
    }
  } else if (m.classes && html.getElementsByClassName) {
    els = findClasses(roots, m.classes);
    if (m.tag) {
      els = filterTag(els, m.tag);
    }
  } else {
    els = findTag(roots, m.tag || '*');
    if (m.classes) {
      _ref2 = m.classes;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        cls = _ref2[_j];
        els = filterAttr(els, 'class', '~=', cls);
      }
    }
  }
  if (m.attrs) {
    _ref3 = m.attrs;
    for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
      attr = _ref3[_k];
      els = filterAttr(els, attr.name, attr.op, attr.val);
    }
  }
  if (m.pseudos) {
    _ref4 = m.pseudos;
    for (_l = 0, _len4 = _ref4.length; _l < _len4; _l++) {
      pseudo = _ref4[_l];
      els = filterPseudo(els, pseudo.name, pseudo.val);
    }
  }
  return els;
};
findId = function(roots, id) {
  var el, root, _i, _len;
  el = document.getElementById(id);
  if (el) {
    for (_i = 0, _len = roots.length; _i < _len; _i++) {
      root = roots[_i];
      if (contains(root, el)) {
        return [el];
      }
    }
  }
  return [];
};
findClasses = function(roots, classes) {
  var cls, el, els, root, _i, _j, _k, _len, _len2, _len3, _ref;
  els = [];
  for (_i = 0, _len = roots.length; _i < _len; _i++) {
    root = roots[_i];
    for (_j = 0, _len2 = classes.length; _j < _len2; _j++) {
      cls = classes[_j];
      _ref = root.getElementsByClassName(cls);
      for (_k = 0, _len3 = _ref.length; _k < _len3; _k++) {
        el = _ref[_k];
        els.push(el);
      }
    }
  }
  return uniq(els);
};
findTag = function(roots, tag) {
  var el, els, root, _i, _j, _len, _len2, _ref;
  els = [];
  for (_i = 0, _len = roots.length; _i < _len; _i++) {
    root = roots[_i];
    _ref = root.getElementsByTagName(tag);
    for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
      el = _ref[_j];
      els.push(el);
    }
  }
  return els;
};
filterTag = function(els, tag) {
  return els.filter(function(el) {
    return el.nodeName.toLowerCase() === tag;
  });
};
filterClasses = function(els, classes) {
  var cls, _i, _len, _ref;
  _ref = m.classes;
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    cls = _ref[_i];
    els = filterAttr(els, roots, 'class', '~=', cls);
  }
  return els;
};
filterAttr = function(els, name, op, val) {
  var pattern, _ref;
  if (val && ((_ref = val[0]) === '"' || _ref === '\'') && val[0] === val[val.length - 1]) {
    val = val.substr(1, val.length - 2);
  }
  if (!op) {
    return els.filter(function(el) {
      return el.getAttribute(name) !== null;
    });
  } else if (op === '=') {
    return els.filter(function(el) {
      return el.getAttribute(name) === val;
    });
  } else if (op === '!=') {
    return els.filter(function(el) {
      return el.getAttribute(name) !== val;
    });
  }
  pattern = (function() {
    switch (op) {
      case '^=':
        return memoRegExp("^" + val);
      case '$=':
        return memoRegExp("" + val + "$");
      case '*=':
        return memoRegExp("" + val);
      case '~=':
        return memoRegExp("(^|\\s+)" + val + "(\\s+|$)");
      case '|=':
        return memoRegExp("^" + val + "(-|$)");
    }
  })();
  return els.filter(function(el) {
    var attr;
    return (attr = el.getAttribute(name)) !== null && pattern.test(attr);
  });
};
filterPseudo = function(els, name, val) {
  var pseudo;
  pseudo = sel.pseudos[name];
  if (!pseudo) {
    throw new Error("no pseudo with name: " + name);
  }
  return els.filter(function(el) {
    return pseudo(el, val);
  });
};
/* parser.coffee */
attrPattern = /(?:\[\s*([-\w]+)\s*(?:([~|^$*!]?=)\s*([-\w]+|['"][^'"]*['"])\s*)?\])/g;
pseudoPattern = /(?:::?([-\w]+)(?:\((\([^()]+\)|[^()]+)\))?)/g;
selectorPattern = RegExp("^\\s*(?:(?:(\\*|\\w+))?(?:\\#([-\\w]+))?(?:\\.([-\\.\\w]+))?(" + attrPattern.source + "*)(" + pseudoPattern.source + "*))([+~>\\s]+)?(,)?");
selectorGroups = {
  all: 0,
  tag: 1,
  id: 2,
  classes: 3,
  attrsAll: 4,
  pseudosAll: 8,
  combinator: 11,
  comma: 12
};
attrGroups = ['attrName', 'attrOp', 'attrVal'];
pseudoGroups = ['pseudoName', 'pseudoVal'];
parseChunk = function(state) {
  var group, m, name, rest;
  rest = state.selector.substr(state.selector.length - state.left);
  if (!(m = selectorPattern.exec(rest))) {
    throw new Error('Parse error.');
  }
  for (name in selectorGroups) {
    group = selectorGroups[name];
    m[name] = m[group];
  }
  state.left -= m.all.length;
  if (m.tag) {
    m.tag = m.tag.toLowerCase();
  }
  if (m.classes) {
    m.classes = m.classes.toLowerCase().split('.');
  }
  if (m.attrsAll) {
    m.attrs = [];
    m.attrsAll.replace(attrPattern, function(all, name, op, val) {
      m.attrs.push({
        name: name,
        op: op,
        val: val
      });
      return "";
    });
  }
  if (m.pseudosAll) {
    m.pseudos = [];
    m.pseudosAll.replace(pseudoPattern, function(all, name, val) {
      if (name === 'not') {
        m.not = parse(val);
      } else {
        m.pseudos.push({
          name: name,
          val: val
        });
      }
      return "";
    });
  }
  if (!state.left) {
    m.combinator = '$';
  } else if (m.comma) {
    m.combinator = ',';
  } else {
    m.combinator = m.combinator.trim() || ' ';
  }
  return m;
};
parseSimple = function(type, state) {
  var m;
  m = parseChunk(state);
  m.type = type;
  switch (m.combinator) {
    case ' ':
    case '>':
      m.child = parseSimple(m.combinator, state);
      break;
    case '+':
    case '~':
    case ',':
      state.rewind = m.combinator;
      break;
    case '$':
      state.rewind = null;
  }
  return m;
};
parse = function(selector) {
  var m, state;
  state = {
    selector: selector,
    left: selector.length
  };
  m = parseSimple(' ', state);
  while (state.rewind) {
    m = {
      type: state.rewind,
      children: [m, parseSimple(' ', state)]
    };
  }
  return m;
};
/* eval.coffee */
evaluate = function(m, roots) {
  var ancestorRoots, els, sibs;
  els = [];
  switch (m.type) {
    case ' ':
    case '>':
      ancestorRoots = roots.filter(function(root, i) {
        return !(i && contains(roots[i - 1], root));
      });
      els = find(ancestorRoots, m);
      if (m.type === '>') {
        els = els.filter(function(el) {
          return roots.some(function(root) {
            return el.parentNode === root;
          });
        });
      }
      if (m.not) {
        els = difference(els, find(roots, m.not));
      }
      if (m.child) {
        els = evaluate(m.child, els);
      }
      break;
    case '+':
    case '~':
    case ',':
      sibs = evaluate(m.children[0], roots);
      els = evaluate(m.children[1], roots);
      if (m.type === ',') {
        els = uniq(els.concat(sibs));
      } else if (m.type === '+') {
        sibs = sibs.map(function(el) {
          return nextElementSibling(el);
        });
        sibs.sort(elCmp);
        els = intersect(els, sibs);
      } else if (m.type === '~') {
        els = els.filter(function(el, i) {
          return el.parentNode && sibs.some(function(sib) {
            return sib !== el && sib.parentNode === el.parentNode && elCmp(sib, el) === -1;
          });
        });
      }
  }
  return els;
};
/* select.coffee */
select = document.querySelector && document.querySelectorAll ? function(selector, roots) {
  var el, els, root, _i, _j, _len, _len2, _ref;
  try {
    els = [];
    for (_i = 0, _len = roots.length; _i < _len; _i++) {
      root = roots[_i];
      _ref = root.querySelectorAll(selector);
      for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
        el = _ref[_j];
        els.push(el);
      }
    }
    return uniq(els);
  } catch (e) {
    return evaluate(parse(selector), roots);
  }
} : function(selector, roots) {
  return evaluate(parse(selector), roots);
};
normalizeRoots = function(roots) {
  if (!roots) {
    return [document];
  } else if (typeof roots === 'string') {
    return select(roots, [document]);
  } else if (typeof roots === 'object' && isFinite(roots.length)) {
    return roots;
  } else {
    return [roots];
  }
};
sel.sel = function(selector, roots) {
  roots = normalizeRoots(roots);
  if (!selector) {
    return [];
  } else if (selector === window || selector === document) {
    return [selector];
  } else if (selector.nodeType === 1) {
    if (roots.some(function(root) {
      return contains(root, selector);
    })) {
      return [selector];
    } else {
      return [];
    }
  } else {
    return select(selector, roots);
  }
};
/* pseudos.coffee */
nthPattern = /\s*((?:\+|\-)?(\d*))n\s*((?:\+|\-)\s*\d+)?\s*/;
children = function(el, ofType) {
  var child, _i, _len, _ref, _results;
  _ref = el.childNodes;
  _results = [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    child = _ref[_i];
    if (child.nodeType === 1 && (!ofType || child.nodeName === ofType)) {
      _results.push(child);
    }
  }
  return _results;
};
checkNthExpr = function(el, els, a, b) {
  if (!a) {
    return el === els[b - 1];
  } else {
    
        for (var i = b; (a > 0 ? i <= els.length : i >= 1); i += a)
            if (el === els[i-1])
                return true;
                
        ;
    return false;
  }
};
checkNth = function(el, els, val) {
  var a, b, m;
  if (!val) {
    return false;
  } else if (isFinite(val)) {
    return el === els[val - 1];
  } else if (val === 'even') {
    return checkNthExpr(el, els, 2, 0);
  } else if (val === 'odd') {
    return checkNthExpr(el, els, 2, 1);
  } else if (m = nthPattern.exec(val)) {
    a = m[2] ? parseInt(m[1]) : parseInt(m[1] + '1');
    b = m[3] ? parseInt(m[3].replace(/\s*/, '')) : 0;
    return checkNthExpr(el, els, a, b);
  } else {
    throw new Error('invalid nth expression');
  }
};
sel.pseudos = {
  'nth-child': function(el, val) {
    var els, p;
    return (p = el.parentNode) && (els = children(p)) && checkNth(el, els, val);
  },
  'nth-last-child': function(el, val) {
    var els, p;
    return (p = el.parentNode) && (els = children(p).reverse()) && checkNth(el, els, val);
  },
  'nth-of-type': function(el, val) {
    var els, p;
    return (p = el.parentNode) && (els = children(p, el.nodeName)) && checkNth(el, els, val);
  },
  'nth-last-of-type': function(el, val) {
    var els, p;
    return (p = el.parentNode) && (els = children(p, el.nodeName).reverse()) && checkNth(el, els, val);
  },
  'first-child': function(el) {
    return sel.pseudos['nth-child'](el, 1);
  },
  'last-child': function(el) {
    return sel.pseudos['nth-last-child'](el, 1);
  },
  'first-of-type': function(el) {
    return sel.pseudos['nth-of-type'](el, 1);
  },
  'last-of-type': function(el) {
    return sel.pseudos['nth-last-of-type'](el, 1);
  },
  'only-child': function(el) {
    var els, p;
    return (p = el.parentNode) && (els = children(p)) && (els.length === 1) && (el === els[0]);
  },
  'only-of-type': function(el) {
    var els, p;
    return (p = el.parentNode) && (els = children(p, el.nodeName)) && (els.length === 1) && (el === els[0]);
  },
  contains: function(el, val) {
    var _ref;
    return ((_ref = el.textContent) != null ? _ref : el.innerText).indexOf(val) >= 0;
  },
  target: function(el) {
    return el.getAttribute('id') === location.hash.substr(1);
  },
  checked: function(el) {
    return el.checked;
  },
  enabled: function(el) {
    return !el.disabled;
  },
  disabled: function(el) {
    return el.disabled;
  },
  empty: function(el) {
    return !el.childNodes.length;
  }
};