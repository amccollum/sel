(function(sel) {
  /* util.coffee */
  var attrPattern, checkNth, combine, contains, create, eachElement, elCmp, evaluate, extend, filter, filterDescendents, find, html, name, nextElementSibling, normalizeRoots, nthPattern, parentMap, parse, parseSimple, pseudoPattern, select, selectorGroups, selectorPattern, synonym, tagPattern, _attrMap, _positionalPseudos, _ref;
  html = document.documentElement;
  extend = function(a, b) {
    var x, _i, _len;
    for (_i = 0, _len = b.length; _i < _len; _i++) {
      x = b[_i];
      a.push(x);
    }
    return a;
  };
  eachElement = function(el, first, next, fn) {
    el = el[first];
    while (el) {
      if (el.nodeType === 1) {
        fn(el);
      }
      el = el[next];
    }
  };
  nextElementSibling = html.nextElementSibling ? function(el) {
    return el.nextElementSibling;
  } : function(el) {
    el = el.nextSibling;
    while (el && el.nodeType !== 1) {
      el = el.nextSibling;
    }
    return el;
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
  elCmp = html.compareDocumentPosition ? function(a, b) {
    if (a === b) {
      return 0;
    } else if (a.compareDocumentPosition(b) & 4) {
      return -1;
    } else {
      return 1;
    }
  } : html.sourceIndex ? function(a, b) {
    if (a === b) {
      return 0;
    } else if (a.sourceIndex < b.sourceIndex) {
      return -1;
    } else {
      return 0;
    }
  } : void 0;
  filterDescendents = function(els) {
    return els.filter(function(el, i) {
      return el && !(i && (els[i - 1] === el || contains(els[i - 1], el)));
    });
  };
  combine = function(a, b, aRest, bRest, map) {
    var i, j, r;
    r = [];
    i = 0;
    j = 0;
    while (i < a.length && j < b.length) {
      switch (map[elCmp(a[i], b[j])]) {
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
  sel.union = function(a, b) {
    return combine(a, b, true, true, {
      '0': 0,
      '-1': 1,
      '1': 2
    });
  };
  sel.intersection = function(a, b) {
    return combine(a, b, false, false, {
      '0': 0,
      '-1': -1,
      '1': -2
    });
  };
  sel.difference = function(a, b) {
    return combine(a, b, true, false, {
      '0': -1,
      '-1': 1,
      '1': -2
    });
  };
  /* find.coffee */
  _attrMap = {
    'tag': 'tagName',
    'class': 'className'
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
  find = function(roots, m) {
    var els;
    if (m.id) {
      els = [];
      roots.forEach(function(root) {
        var el;
        el = (root.ownerDocument || root).getElementById(m.id);
        if (el && contains(root, el)) {
          els.push(el);
        }
      });
    } else if (m.classes && html.getElementsByClassName) {
      els = roots.map(function(root) {
        return m.classes.map(function(cls) {
          return root.getElementsByClassName(cls);
        }).reduce(sel.union);
      }).reduce(extend, []);
      m.classes = null;
    } else {
      els = roots.map(function(root) {
        return root.getElementsByTagName(m.tag || '*');
      }).reduce(extend, []);
      m.tag = null;
    }
    if (els && els.length) {
      return filter(els, m);
    } else {
      return [];
    }
  };
  filter = function(els, m) {
    if (m.tag) {
      els = els.filter(function(el) {
        return el.nodeName.toLowerCase() === m.tag;
      });
    }
    if (m.classes) {
      m.classes.forEach(function(cls) {
        els = els.filter(function(el) {
          return (" " + el.className + " ").indexOf(" " + cls + " ") >= 0;
        });
      });
    }
    if (m.attrs) {
      m.attrs.forEach(function(_arg) {
        var name, op, val, _ref;
        name = _arg.name, op = _arg.op, val = _arg.val;
        name = _attrMap[name] || name;
        if (val && ((_ref = val[0]) === '"' || _ref === '\'') && val[0] === val[val.length - 1]) {
          val = val.substr(1, val.length - 2);
        }
        els = els.filter(function(el) {
          var attr, value, _ref2;
          attr = (_ref2 = el[name]) != null ? _ref2 : el.getAttribute(name);
          value = attr + "";
          return (attr || (el.attributes && el.attributes[name] && el.attributes[name].specified)) && (!op ? true : op === '=' ? value === val : op === '!=' ? value !== val : op === '*=' ? value.indexOf(val) >= 0 : op === '^=' ? value.indexOf(val) === 0 : op === '$=' ? value.substr(value.length - val.length) === val : op === '~=' ? (" " + value + " ").indexOf(" " + val + " ") >= 0 : op === '|=' ? value === val || (value.indexOf(val) === 0 && value[val.length] === '-') : false);
        });
      });
    }
    if (m.pseudos) {
      m.pseudos.forEach(function(_arg) {
        var filtered, first, name, next, pseudo, val;
        name = _arg.name, val = _arg.val;
        pseudo = sel.pseudos[name];
        if (!pseudo) {
          throw new Error("no pseudo with name: " + name);
        }
        if (name in _positionalPseudos) {
          first = _positionalPseudos[name] ? 'lastChild' : 'firstChild';
          next = _positionalPseudos[name] ? 'previousSibling' : 'nextSibling';
          els.forEach(function(el) {
            var indices, parent;
            if ((parent = el.parentNode) && parent._sel_children === void 0) {
              indices = {
                '*': 0
              };
              eachElement(parent, first, next, function(el) {
                el._sel_index = ++indices['*'];
                return el._sel_indexOfType = indices[el.nodeName] = (indices[el.nodeName] || 0) + 1;
              });
              parent._sel_children = indices;
            }
          });
        }
        filtered = els.filter(function(el) {
          return pseudo(el, val);
        });
        if (name in _positionalPseudos) {
          els.forEach(function(el) {
            var indices, parent;
            if ((parent = el.parentNode) && parent._sel_children !== void 0) {
              indices = {
                '*': 0
              };
              eachElement(parent, first, next, function(el) {
                return el._sel_index = el._sel_indexOfType = void 0;
              });
              parent._sel_children = void 0;
            }
          });
        }
        els = filtered;
      });
    }
    return els;
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
        return ((i - b) % a === 0) && ((i - b) / a >= 0);
      }
    } else {
      throw new Error('invalid nth expression');
    }
  };
  sel.pseudos = {
    'first-child': function(el) {
      return el._sel_index === 1;
    },
    'only-child': function(el) {
      return el._sel_index === 1 && el.parentNode._sel_children['*'] === 1;
    },
    'nth-child': function(el, val) {
      return checkNth(el._sel_index, val);
    },
    'first-of-type': function(el) {
      return el._sel_indexOfType === 1;
    },
    'only-of-type': function(el) {
      return el._sel_indexOfType === 1 && el.parentNode._sel_children[el.nodeName] === 1;
    },
    'nth-of-type': function(el, val) {
      return checkNth(el._sel_indexOfType, val);
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
  _ref = {
    'has': 'with',
    'last-child': 'first-child',
    'nth-last-child': 'nth-child',
    'last-of-type': 'first-of-type',
    'nth-last-of-type': 'nth-of-type'
  };
  for (synonym in _ref) {
    name = _ref[synonym];
    sel.pseudos[synonym] = sel.pseudos[name];
  }
  /* parser.coffee */
  attrPattern = /(?:\[\s*([-\w]+)\s*(?:([~|^$*!]?=)\s*([-\w]+|['"][^'"]*['"])\s*)?\])/g;
  pseudoPattern = /(?:::?([-\w]+)(?:\((\([^()]+\)|[^()]+)\))?)/g;
  selectorPattern = RegExp("^\\s*(?:(?:(\\*|\\w+))?(?:\\#([-\\w]+))?(?:\\.([-\\.\\w]+))?(" + attrPattern.source + "*)(" + pseudoPattern.source + "*))([+~>\\s]+)?(,)?");
  selectorGroups = {
    tag: 1,
    id: 2,
    classes: 3,
    attrsAll: 4,
    pseudosAll: 8,
    combinator: 11,
    comma: 12
  };
  parseSimple = function(type, state) {
    var group, m, name, rest;
    rest = state.selector.substr(state.selector.length - state.left);
    if (!(m = selectorPattern.exec(rest))) {
      throw new Error("Parse error: " + rest);
    }
    state.left -= m[0].length;
    for (name in selectorGroups) {
      group = selectorGroups[name];
      m[name] = m[group];
    }
    m.type = type;
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
  parentMap = {
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
    var els, parent;
    parent = (root || document).createElement(parentMap[tagPattern.exec(html)[1]] || 'div');
    parent.innerHTML = html;
    els = [];
    eachElement(parent, 'firstChild', 'nextSibling', function(el) {
      return els.push(el);
    });
    return els;
  };
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
    } else if (tagPattern.test(selector)) {
      return create(selector, roots[0]);
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