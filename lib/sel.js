(function(sel) {
  /* util.coffee */
  var attrGroups, attrPattern, checkNth, combine, comparePosition, contains, elCmp, evaluate, extend, filterAll, filterAttr, filterClasses, filterDescendents, filterPseudo, filterTag, find, findClasses, findId, findTag, html, name, nextElementSibling, normalizeRoots, nthPattern, parse, parseChunk, parseSimple, pseudoGroups, pseudoPattern, select, selectorGroups, selectorPattern, synonym, _attrMap, _differenceMap, _intersectionMap, _positionalPseudos, _synonyms, _unionMap;
  html = document.documentElement;
  extend = function(a, b) {
    var x, _i, _len;
    for (_i = 0, _len = b.length; _i < _len; _i++) {
      x = b[_i];
      a.push(x);
    }
    return a;
  };
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
  filterDescendents = function(els) {
    return els.filter(function(el, i) {
      return el && !(i && (els[i - 1] === el || contains(els[i - 1], el)));
    });
  };
  combine = function(a, b, aRest, bRest, fn) {
    var i, j, r;
    r = [];
    i = 0;
    j = 0;
    while (i < a.length && j < b.length) {
      switch (fn(a[i], b[j])) {
        case -1:
          i++;
          break;
        case -2:
          j++;
          break;
        case 1:
          r.push(a[i++]);
          break;
        case 2:
          r.push(b[j++]);
          break;
        case 0:
          r.push(a[i++]);
          j++;
      }
    }
    if (aRest) {
      while (i < a.length) {
        r.push(a[i++]);
      }
    }
    if (bRest) {
      while (j < b.length) {
        r.push(b[j++]);
      }
    }
    return r;
  };
  _unionMap = {
    '0': 0,
    '-1': 1,
    '1': 2
  };
  sel.union = function(a, b) {
    return combine(a, b, true, true, function(ai, bi) {
      return _unionMap[elCmp(ai, bi)];
    });
  };
  _intersectionMap = {
    '0': 0,
    '-1': -1,
    '1': -2
  };
  sel.intersection = function(a, b) {
    return combine(a, b, false, false, function(ai, bi) {
      return _intersectionMap[elCmp(ai, bi)];
    });
  };
  _differenceMap = {
    '0': -1,
    '-1': 1,
    '1': -2
  };
  sel.difference = function(a, b) {
    return combine(a, b, true, false, function(ai, bi) {
      return _differenceMap[elCmp(ai, bi)];
    });
  };
  /* find.coffee */
  find = function(roots, m) {
    var els;
    if (m.id) {
      els = findId(roots, m.id);
    } else if (m.classes && html.getElementsByClassName) {
      els = findClasses(roots, m.classes);
      m.classes = null;
    } else {
      els = findTag(roots, m.tag || '*');
      m.tag = null;
    }
    return filterAll(els, m);
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
    return roots.map(function(root) {
      return classes.map(function(cls) {
        return root.getElementsByClassName(cls);
      }).reduce(sel.union);
    }).reduce(extend, []);
  };
  findTag = function(roots, tag) {
    return roots.map(function(root) {
      return root.getElementsByTagName(tag);
    }).reduce(extend, []);
  };
  filterAll = function(els, m) {
    if (m.tag) {
      els = filterTag(els, m.tag);
    }
    if (m.classes) {
      els = filterClasses(els, m.classes);
    }
    if (m.attrs) {
      m.attrs.forEach(function(attr) {
        els = filterAttr(els, attr.name, attr.op, attr.val);
      });
    }
    if (m.pseudos) {
      m.pseudos.forEach(function(pseudo) {
        els = filterPseudo(els, pseudo.name, pseudo.val);
      });
    }
    return els;
  };
  filterTag = function(els, tag) {
    return els.filter(function(el) {
      return el.nodeName.toLowerCase() === tag;
    });
  };
  filterClasses = function(els, classes) {
    classes.forEach(function(cls) {
      els = els.filter(function(el) {
        return (" " + el.className + " ").indexOf(" " + cls + " ") >= 0;
      });
    });
    return els;
  };
  _attrMap = {
    'tag': 'tagName',
    'class': 'className'
  };
  filterAttr = function(els, name, op, val) {
    var _ref;
    if (val && ((_ref = val[0]) === '"' || _ref === '\'') && val[0] === val[val.length - 1]) {
      val = val.substr(1, val.length - 2);
    }
    name = _attrMap[name] || name;
    return els.filter(function(el) {
      var attr, value, _ref2;
      attr = (_ref2 = el[name]) != null ? _ref2 : el.getAttribute(name);
      value = attr + "";
      return (attr || (el.attributes && el.attributes[name] && el.attributes[name].specified)) && (!op ? true : op === '=' ? value === val : op === '!=' ? value !== val : op === '*=' ? value.indexOf(val) >= 0 : op === '^=' ? value.indexOf(val) === 0 : op === '$=' ? value.substr(value.length - val.length) === val : op === '~=' ? (" " + value + " ").indexOf(" " + val + " ") >= 0 : op === '|=' ? value === val || (value.indexOf(val) === 0 && value[val.length] === '-') : false);
    });
  };
  _positionalPseudos = {
    'nth-child': false,
    'nth-of-type': false,
    'first-child': false,
    'first-of-type': false,
    'nth-last-child': true,
    'nth-last-of-type': true,
    'last-child': true,
    'last-of-type': true,
    'only-child': false,
    'only-of-type': false
  };
  filterPseudo = function(els, name, val) {
    var filtered, first, next, pseudo;
    pseudo = sel.pseudos[name];
    if (!pseudo) {
      throw new Error("no pseudo with name: " + name);
    }
    if (name in _positionalPseudos) {
      first = _positionalPseudos[name] ? 'lastChild' : 'firstChild';
      next = _positionalPseudos[name] ? 'previousSibling' : 'nextSibling';
      els.forEach(function(el) {
        var indices, parent;
        indices = {
          '*': 0
        };
        el = (parent = el.parentNode) && parent[first];
        while (el) {
          if (el.nodeType === 1) {
            if (el._sel_index !== void 0) {
              return;
            }
            el._sel_index = ++indices['*'];
            el._sel_indexOfType = indices[el.nodeName] = (indices[el.nodeName] || 0) + 1;
          }
          el = el[next];
        }
        if (parent) {
          parent._sel_children = indices;
        }
      });
    }
    filtered = els.filter(function(el) {
      return pseudo(el, val);
    });
    if (name in _positionalPseudos) {
      els.forEach(function(el) {
        var parent;
        el = (parent = el.parentNode) && parent[first];
        while (el) {
          if (el.nodeType === 1) {
            if (el._sel_index === void 0) {
              return;
            }
            el._sel_index = el._sel_indexOfType = void 0;
          }
          el = el[next];
        }
        if (parent) {
          parent._sel_children = void 0;
        }
      });
    }
    return filtered;
  };
  /* pseudos.coffee */
  nthPattern = /\s*((?:\+|\-)?(\d*))n\s*((?:\+|\-)\s*\d+)?\s*/;
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
      return checkNth(el._sel_index, val);
    },
    'nth-of-type': function(el, val) {
      return checkNth(el._sel_indexOfType, val);
    },
    'first-child': function(el) {
      return el._sel_index === 1;
    },
    'first-of-type': function(el) {
      return el._sel_indexOfType === 1;
    },
    'only-child': function(el) {
      return el._sel_index === 1 && el.parentNode._sel_children['*'] === 1;
    },
    'only-of-type': function(el) {
      return el._sel_indexOfType === 1 && el.parentNode._sel_children[el.nodeName] === 1;
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
    },
    "with": function(el, val) {
      return select(val, [el]).length > 0;
    },
    without: function(el, val) {
      return select(val, [el]).length === 0;
    }
  };
  _synonyms = {
    'has': 'with',
    'nth-last-child': 'nth-child',
    'nth-last-of-type': 'nth-of-type',
    'last-child': 'first-child',
    'last-of-type': 'first-of-type'
  };
  for (synonym in _synonyms) {
    name = _synonyms[synonym];
    sel.pseudos[synonym] = sel.pseudos[name];
  }
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
          outerRoots = filterDescendents(roots);
          els = find(outerRoots, m);
          if (m.type === '>') {
            roots.forEach(function(el) {
              el._sel_mark = true;
            });
            els = els.filter(function(el) {
              if ((el = el.parentNode)) {
                return el._sel_mark;
              }
            });
            roots.forEach(function(el) {
              el._sel_mark = false;
            });
          }
          if (m.not) {
            els = sel.difference(els, find(outerRoots, m.not));
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
            els = sel.union(sibs, els);
          } else if (m.type === '+') {
            sibs.forEach(function(el) {
              if ((el = nextElementSibling(el))) {
                el._sel_mark = true;
              }
            });
            els = els.filter(function(el) {
              return el._sel_mark;
            });
            sibs.forEach(function(el) {
              if ((el = nextElementSibling(el))) {
                el._sel_mark = void 0;
              }
            });
          } else if (m.type === '~') {
            sibs.forEach(function(el) {
              while ((el = nextElementSibling(el)) && !el._sel_mark) {
                el._sel_mark = true;
              }
            });
            els = els.filter(function(el) {
              return el._sel_mark;
            });
            sibs.forEach(function(el) {
              while ((el = nextElementSibling(el)) && el._sel_mark) {
                el._sel_mark = void 0;
              }
            });
          }
      }
    }
    return els;
  };
  /* select.coffee */
  select = document.querySelector && document.querySelectorAll ? function(selector, roots) {
    try {
      return roots.map(function(root) {
        return root.querySelectorAll(selector);
      }).reduce(extend, []);
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
      if (roots.sort) {
        roots.sort(elCmp);
      }
      return filterDescendents(roots);
    } else {
      return [roots];
    }
  };
  return sel.sel = function(selector, roots) {
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
})(typeof exports !== "undefined" && exports !== null ? exports : (this['sel'] = {}));