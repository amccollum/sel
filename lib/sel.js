(function(sel) {
  /* util.coffee */
  var attrGroups, attrPattern, checkNth, childIndex, comparePosition, contains, elCmp, evaluate, filterAttr, filterClasses, filterPseudo, filterTag, find, findClasses, findId, findTag, html, nextElementSibling, normalizeRoots, nthPattern, parse, parseChunk, parseSimple, pseudoGroups, pseudoPattern, select, selectorGroups, selectorPattern, subsume;
  html = document.documentElement;
  contains = html.compareDocumentPosition != null ? function(a, b) {
    return (a.compareDocumentPosition(b) & 16) === 16;
  } : html.contains != null ? function(a, b) {
    if (a.documentElement) {
      return b.ownerDocument === a;
    } else {
      return a !== b && a.contains(b);
    }
  } : function(a, b) {
    if (a.documentElement) {
      return b.ownerDocument === a;
    }
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
  elCmp = function(a, b) {
    if (!a) {
      return -1;
    } else if (!b) {
      return 1;
    } else if (a === b) {
      return 0;
    } else if (comparePosition(a, b) & 4) {
      return -1;
    } else {
      return 1;
    }
  };
  subsume = function(arr) {
    return arr.filter(function(el, i) {
      return el && !(i && (arr[i - 1] === el || contains(arr[i - 1], el)));
    });
  };
  sel.union = function(a, b) {
    var arr, i, j;
    arr = [];
    i = 0;
    j = 0;
    while (i < a.length && j < b.length) {
      switch (elCmp(a[i], b[j])) {
        case -1:
          arr.push(a[i++]);
          break;
        case 1:
          arr.push(b[j++]);
          break;
        case 0:
          arr.push(a[i++]);
          j++;
      }
    }
    while (i < a.length) {
      arr.push(a[i++]);
    }
    while (j < b.length) {
      arr.push(b[j++]);
    }
    return arr;
  };
  sel.intersection = function(a, b) {
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
  sel.difference = function(a, b) {
    var arr, i, j;
    arr = [];
    i = 0;
    j = 0;
    while (i < a.length && j < b.length) {
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
    while (i < a.length) {
      arr.push(a[i++]);
    }
    return arr;
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
    var doc, el;
    doc = roots[0].ownerDocument || roots[0];
    el = doc.getElementById(id);
    if (el && roots.some(function(root) {
      return contains(root, el);
    })) {
      return [el];
    }
    return [];
  };
  findClasses = function(roots, classes) {
    var cls, els, root, rootEls, _i, _j, _len, _len2;
    els = [];
    for (_i = 0, _len = roots.length; _i < _len; _i++) {
      root = roots[_i];
      rootEls = [];
      for (_j = 0, _len2 = classes.length; _j < _len2; _j++) {
        cls = classes[_j];
        rootEls = sel.union(rootEls, root.getElementsByClassName(cls));
      }
      els = els.concat(rootEls);
    }
    return els;
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
    var _ref;
    if (val && ((_ref = val[0]) === '"' || _ref === '\'') && val[0] === val[val.length - 1]) {
      val = val.substr(1, val.length - 2);
    }
    return els.filter(function(el) {
      var attr;
      return (attr = el.getAttribute(name)) !== null && (!op ? true : op === '=' ? attr === val : op === '!=' ? attr !== val : op === '*=' ? attr.indexOf(val) >= 0 : op === '^=' ? attr.indexOf(val) === 0 : op === '$=' ? attr.substr(attr.length - val.length) === val : op === '~=' ? (" " + attr + " ").indexOf(" " + val + " ") >= 0 : op === '|=' ? attr === val || (attr.indexOf(val) === 0 && attr[val.length] === '-') : false);
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
    var els, outerRoots, sibs;
    els = [];
    if (roots.length) {
      switch (m.type) {
        case ' ':
        case '>':
          outerRoots = subsume(roots);
          els = find(outerRoots, m);
          if (m.type === '>') {
            els = els.filter(function(el) {
              var parent;
              return el && (parent = el.parentNode) && roots.some(function(root) {
                return parent === root;
              });
            });
          }
          if (m.not) {
            els = sel.difference(els, find(roots, m.not));
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
            els = sel.union(els, sibs);
          } else if (m.type === '+') {
            sibs = sibs.map(function(el) {
              return nextElementSibling(el);
            });
            sibs.sort(elCmp);
            els = sel.intersection(els, sibs);
          } else if (m.type === '~') {
            els = els.filter(function(el) {
              var parent;
              return el && (parent = el.parentNode) && sibs.some(function(sib) {
                return sib !== el && sib.parentNode === parent && elCmp(sib, el) === -1;
              });
            });
          }
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
      return els;
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
      if (roots.sort) {
        roots.sort(elCmp);
      }
      return subsume(roots);
    } else {
      return [roots];
    }
  };
  sel.sel = function(selector, roots) {
    roots = normalizeRoots(roots);
    if (!selector) {
      return [];
    } else if (selector === window || selector === 'window') {
      return [window];
    } else if (selector === document || selector === 'document') {
      return [document];
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
  childIndex = function(el, reversed, ofType) {
    var index, next, node, start;
    start = reversed ? 'lastChild' : 'firstChild';
    next = reversed ? 'previousSibling' : 'nextSibling';
    index = 0;
    node = el.parentNode && el.parentNode[start];
    while (node) {
      if (ofType && node.nodeName !== ofType) {
        continue;
      }
      if (node.nodeType === 1) {
        index++;
      }
      if (node === el) {
        return index;
      }
      node = node[next];
    }
    return NaN;
  };
  checkNth = function(i, val) {
    var a, b, m;
    if (!val) {
      return false;
    } else if (isFinite(val)) {
      return i == val;
    } else if (val === 'even') {
      return i % 2 === 0;
    } else if (val === 'odd') {
      return i % 2 === 1;
    } else if (m = nthPattern.exec(val)) {
      a = m[2] ? parseInt(m[1]) : parseInt(m[1] + '1');
      b = m[3] ? parseInt(m[3].replace(/\s*/, '')) : 0;
      if (!a) {
        return i === b;
      } else {
        return (i - b) % a === 0 && (i - b) / a >= 0;
      }
    } else {
      throw new Error('invalid nth expression');
    }
  };
  sel.pseudos = {
    'nth-child': function(el, val) {
      return checkNth(childIndex(el), val);
    },
    'nth-last-child': function(el, val) {
      return checkNth(childIndex(el, true), val);
    },
    'nth-of-type': function(el, val) {
      return checkNth(childIndex(el, false, el.nodeName), val);
    },
    'nth-last-of-type': function(el, val) {
      return checkNth(childIndex(el, true, el.nodeName), val);
    },
    'first-child': function(el) {
      return childIndex(el) === 1;
    },
    'last-child': function(el) {
      return childIndex(el, true) === 1;
    },
    'first-of-type': function(el) {
      return childIndex(el, false, el.nodeName) === 1;
    },
    'last-of-type': function(el) {
      return childIndex(el, true, el.nodeName) === 1;
    },
    'only-child': function(el) {
      return childIndex(el) === 1 && childIndex(el, true) === 1;
    },
    'only-of-type': function(el) {
      return childIndex(el, false, el.nodeName) === 1 && childIndex(el, true, el.nodeName) === 1;
    },
    target: function(el) {
      return el.getAttribute('id') === location.hash.substr(1);
    },
    checked: function(el) {
      return el.checked === true;
    },
    enabled: function(el) {
      return el.disabled === false;
    },
    disabled: function(el) {
      return el.disabled === true;
    },
    selected: function(el) {
      return el.selected === true;
    },
    focus: function(el) {
      return el.ownerDocument.activeElement === el;
    },
    empty: function(el) {
      return !el.childNodes.length;
    },
    contains: function(el, val) {
      var _ref;
      return ((_ref = el.textContent) != null ? _ref : el.innerText).indexOf(val) >= 0;
    }
  };
  return {
    has: function(el, val) {
      return select(val, [el]).length > 0;
    }
  };
})(typeof exports !== "undefined" && exports !== null ? exports : (this.sel = {}));