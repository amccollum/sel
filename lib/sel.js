
(function(sel) {
  /* util.coffee
  */
  var attrPattern, combinatorPattern, combine, contains, create, difference, eachElement, elCmp, evaluate, extend, filter, filterDescendants, find, findRoots, getAttribute, html, intersection, matchesDisconnected, matchesSelector, matching, nextElementSibling, normalizeRoots, outerParents, parentMap, parse, parseSimple, pseudoPattern, pseudos, qSA, select, selectorGroups, selectorPattern, tagPattern, takeElements, union, _attrMap;
  html = document.documentElement;
  extend = function(a, b) {
    var x, _i, _len;
    for (_i = 0, _len = b.length; _i < _len; _i++) {
      x = b[_i];
      a.push(x);
    }
    return a;
  };
  takeElements = function(els) {
    return els.filter(function(el) {
      return el.nodeType === 1;
    });
  };
  eachElement = function(el, first, next, fn) {
    if (first) el = el[first];
    while (el) {
      if (el.nodeType === 1) if (fn(el) === false) break;
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
    if (a.documentElement) return b.ownerDocument === a;
    while (b = b.parentNode) {
      if (a === b) return true;
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
      return 1;
    }
  } : void 0;
  filterDescendants = function(els) {
    return els.filter(function(el, i) {
      return el && !(i && (els[i - 1] === el || contains(els[i - 1], el)));
    });
  };
  outerParents = function(els) {
    return filterDescendents(els.map(function(el) {
      return el.parentNode;
    }));
  };
  findRoots = function(els) {
    var r;
    r = [];
    els.forEach(function(el) {
      while (el.parentNode) {
        el = el.parentNode;
      }
      if (r[r.length - 1] !== el) r.push(el);
    });
    return r;
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
  sel.union = union = function(a, b) {
    return combine(a, b, true, true, {
      '0': 0,
      '-1': 1,
      '1': 2
    });
  };
  sel.intersection = intersection = function(a, b) {
    return combine(a, b, false, false, {
      '0': 0,
      '-1': -1,
      '1': -2
    });
  };
  sel.difference = difference = function(a, b) {
    return combine(a, b, true, false, {
      '0': -1,
      '-1': 1,
      '1': -2
    });
  };
  /* parser.coffee
  */
  attrPattern = /\[\s*([-\w]+)\s*(?:([~|^$*!]?=)\s*(?:([-\w]+)|['"]([^'"]*)['"]\s*(i))\s*)?\]/g;
  pseudoPattern = /::?([-\w]+)(?:\((\([^()]+\)|[^()]+)\))?/g;
  combinatorPattern = /^\s*([,+~]|\/([-\w]+)\/)/;
  selectorPattern = RegExp("^(?:\\s*(>))?\\s*(?:(\\*|\\w+))?(?:\\#([-\\w]+))?(?:\\.([-\\.\\w]+))?((?:" + attrPattern.source + ")*)((?:" + pseudoPattern.source + ")*)(!)?");
  selectorGroups = {
    type: 1,
    tag: 2,
    id: 3,
    classes: 4,
    attrsAll: 5,
    pseudosAll: 11,
    subject: 14
  };
  parse = function(selector) {
    var e, last, result;
    if (selector in parse.cache) return parse.cache[selector];
    result = last = e = parseSimple(selector);
    if (e.compound) e.children = [];
    while (e[0].length < selector.length) {
      selector = selector.substr(last[0].length);
      e = parseSimple(selector);
      if (e.compound) {
        e.children = [result];
        result = e;
      } else if (last.compound) {
        last.children.push(e);
      } else {
        last.child = e;
      }
      last = e;
    }
    return (parse.cache[selector] = result);
  };
  parse.cache = {};
  parseSimple = function(selector) {
    var e, group, name;
    if (e = combinatorPattern.exec(selector)) {
      e.compound = true;
      e.type = e[1].charAt(0);
      if (e.type === '/') e.idref = e[2];
    } else if ((e = selectorPattern.exec(selector)) && e[0].trim()) {
      e.simple = true;
      for (name in selectorGroups) {
        group = selectorGroups[name];
        e[name] = e[group];
      }
      e.type || (e.type = ' ');
      e.tag && (e.tag = e.tag.toLowerCase());
      if (e.classes) e.classes = e.classes.toLowerCase().split('.');
      if (e.attrsAll) {
        e.attrs = [];
        e.attrsAll.replace(attrPattern, function(all, name, op, val, quotedVal, ignoreCase) {
          name = name.toLowerCase();
          val || (val = quotedVal);
          if (op === '=') {
            if (name === 'id' && !e.id) {
              e.id = val;
              return "";
            } else if (name === 'class') {
              if (e.classes) {
                e.classes.append(val);
              } else {
                e.classes = [val];
              }
              return "";
            }
          }
          if (ignoreCase) val = val.toLowerCase();
          e.attrs.push({
            name: name,
            op: op,
            val: val,
            ignoreCase: ignoreCase
          });
          return "";
        });
      }
      if (e.pseudosAll) {
        e.pseudos = [];
        e.pseudosAll.replace(pseudoPattern, function(all, name, val) {
          name = name.toLowerCase();
          e.pseudos.push({
            name: name,
            val: val
          });
          return "";
        });
      }
    } else {
      throw new Error("Parse error at: " + selector);
    }
    return e;
  };
  /* find.coffee
  */
  _attrMap = {
    'tag': function(el) {
      return el.tagName;
    },
    'class': function(el) {
      return el.className;
    }
  };
  getAttribute = function(el, name) {
    if (_attrMap[name]) {
      return _attrMap[name](el);
    } else {
      return el.getAttribute(name);
    }
  };
  find = function(e, roots, matchRoots) {
    var els;
    if (e.id) {
      els = [];
      roots.forEach(function(root) {
        var doc, el;
        doc = root.ownerDocument || root;
        if (root === doc || (root.nodeType === 1 && contains(doc.documentElement, root))) {
          el = doc.getElementById(e.id);
          if (el && contains(root, el)) els.push(el);
        } else {
          extend(els, root.getElementsByTagName(e.tag || '*'));
        }
      });
    } else if (e.classes && find.byClass) {
      els = roots.map(function(root) {
        return e.classes.map(function(cls) {
          return root.getElementsByClassName(cls);
        }).reduce(union);
      }).reduce(extend, []);
      e.ignoreClasses = true;
    } else {
      els = roots.map(function(root) {
        return root.getElementsByTagName(e.tag || '*');
      }).reduce(extend, []);
      if (find.filterComments && (!e.tag || e.tag === '*')) {
        els = takeElements(els);
      }
      e.ignoreTag = true;
    }
    if (els && els.length) {
      els = filter(els, e, roots, matchRoots);
    } else {
      els = [];
    }
    e.ignoreTag = void 0;
    e.ignoreClasses = void 0;
    if (matchRoots) {
      els = union(els, filter(takeElements(roots), e, roots, matchRoots));
    }
    return els;
  };
  filter = function(els, e, roots, matchRoots) {
    if (e.id) {
      els = els.filter(function(el) {
        return el.id === e.id;
      });
    }
    if (e.tag && e.tag !== '*' && !e.ignoreTag) {
      els = els.filter(function(el) {
        return el.nodeName.toLowerCase() === e.tag;
      });
    }
    if (e.classes && !e.ignoreClasses) {
      e.classes.forEach(function(cls) {
        els = els.filter(function(el) {
          return (" " + el.className + " ").indexOf(" " + cls + " ") >= 0;
        });
      });
    }
    if (e.attrs) {
      e.attrs.forEach(function(_arg) {
        var ignoreCase, name, op, val;
        name = _arg.name, op = _arg.op, val = _arg.val, ignoreCase = _arg.ignoreCase;
        els = els.filter(function(el) {
          var attr, value;
          attr = getAttribute(el, name);
          value = attr + "";
          if (ignoreCase) value = value.toLowerCase();
          return (attr || (el.attributes && el.attributes[name] && el.attributes[name].specified)) && (!op ? true : op === '=' ? value === val : op === '!=' ? value !== val : op === '*=' ? value.indexOf(val) >= 0 : op === '^=' ? value.indexOf(val) === 0 : op === '$=' ? value.substr(value.length - val.length) === val : op === '~=' ? (" " + value + " ").indexOf(" " + val + " ") >= 0 : op === '|=' ? value === val || (value.indexOf(val) === 0 && value.charAt(val.length) === '-') : false);
        });
      });
    }
    if (e.pseudos) {
      e.pseudos.forEach(function(_arg) {
        var name, pseudo, val;
        name = _arg.name, val = _arg.val;
        pseudo = pseudos[name];
        if (!pseudo) throw new Error("no pseudo with name: " + name);
        if (pseudo.batch) {
          els = pseudo(els, val, roots, matchRoots);
        } else {
          els = els.filter(function(el) {
            return pseudo(el, val);
          });
        }
      });
    }
    return els;
  };
  (function() {
    var div;
    div = document.createElement('div');
    div.innerHTML = '<a href="#"></a>';
    if (div.firstChild.getAttribute('href') !== '#') {
      _attrMap['href'] = function(el) {
        return el.getAttribute('href', 2);
      };
      _attrMap['src'] = function(el) {
        return el.getAttribute('src', 2);
      };
    }
    div.innerHTML = '<div class="a b"></div><div class="a"></div>';
    if (div.getElementsByClassName && div.getElementsByClassName('b').length) {
      div.lastChild.className = 'b';
      if (div.getElementsByClassName('b').length === 2) find.byClass = true;
    }
    div.innerHTML = '';
    div.appendChild(document.createComment(''));
    if (div.getElementsByTagName('*').length > 0) find.filterComments = true;
    div = null;
  })();
  /* pseudos.coffee
  */
  sel.pseudos = pseudos = {
    selected: function(el) {
      return el.selected === true;
    },
    focus: function(el) {
      return el.ownerDocument.activeElement === el;
    },
    enabled: function(el) {
      return el.disabled === false;
    },
    checked: function(el) {
      return el.checked === true;
    },
    disabled: function(el) {
      return el.disabled === true;
    },
    root: function(el) {
      return el.ownerDocument.documentElement === el;
    },
    target: function(el) {
      return el.id === location.hash.substr(1);
    },
    empty: function(el) {
      return !el.childNodes.length;
    },
    dir: function(el, val) {
      while (el) {
        if (el.dir) return el.dir === val;
        el = el.parentNode;
      }
      return false;
    },
    lang: function(el, val) {
      var lang;
      while (el) {
        if ((lang = el.lang)) {
          return lang === val || lang.indexOf("" + val + "-") === 0;
        }
        el = el.parentNode;
      }
      el = select('head meta[http-equiv="Content-Language" i]', el.ownerDocument)[0];
      if (el) {
        lang = getAttribute(el, 'content').split(',')[0];
        return lang === val || lang.indexOf("" + val + "-") === 0;
      }
      return false;
    },
    'local-link': function(el, val) {
      var href, i, location;
      if (!el.href) return false;
      href = el.href.replace(/#.*?$/, '');
      location = el.ownerDocument.location.href.replace(/#.*?$/, '');
      if (val === void 0) {
        return href === location;
      } else {
        href = href.split('/').slice(2);
        location = location.split('/').slice(2);
        for (i = 0; i <= val; i += 1) {
          if (href[i] !== location[i]) return false;
        }
        return true;
      }
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
  pseudos['has'] = pseudos['with'];
  pseudos.matches = function(els, val, roots, matchRoots) {
    return intersection(els, select(val, roots, matchRoots));
  };
  pseudos.matches.batch = true;
  pseudos.not = function(els, val, roots, matchRoots) {
    return difference(els, select(val, roots, matchRoots));
  };
  pseudos.not.batch = true;
  (function() {
    var checkNth, fn, matchColumn, name, nthMatch, nthMatchPattern, nthPattern, nthPositional, positionalPseudos;
    nthPattern = /^\s*(even|odd|(?:(\+|\-)?(\d*)(n))?(?:\s*(\+|\-)?\s*(\d+))?)(?:\s+of\s+(.*?))?\s*$/;
    checkNth = function(i, m) {
      var a, b;
      a = parseInt((m[2] || '+') + (m[3] === '' ? (m[4] ? '1' : '0') : m[3]));
      b = parseInt((m[5] || '+') + (m[6] === '' ? '0' : m[6]));
      if (m[1] === 'even') {
        return i % 2 === 0;
      } else if (m[1] === 'odd') {
        return i % 2 === 1;
      } else if (a) {
        return ((i - b) % a === 0) && ((i - b) / a >= 0);
      } else if (b) {
        return i === b;
      } else {
        throw new Error('Invalid nth expression');
      }
    };
    matchColumn = function(nth, reversed) {
      var first, next;
      first = reversed ? 'lastChild' : 'firstChild';
      next = reversed ? 'previousSibling' : 'nextSibling';
      return function(els, val, roots) {
        var check, m, set;
        set = [];
        if (nth) {
          m = nthPattern.exec(val);
          check = function(i) {
            return checkNth(i, m);
          };
        }
        select('table', roots).forEach(function(table) {
          var col, max, min, tbody, _i, _len, _ref;
          if (!nth) {
            col = select(val, [table])[0];
            min = 0;
            eachElement(col, 'previousSibling', 'previousSibling', function(col) {
              return min += parseInt(col.getAttribute('span') || 1);
            });
            max = min + parseInt(col.getAttribute('span') || 1);
            check = function(i) {
              return (min < i && i <= max);
            };
          }
          _ref = table.tBodies;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            tbody = _ref[_i];
            eachElement(tbody, 'firstChild', 'nextSibling', function(row) {
              var i;
              if (row.tagName.toLowerCase() !== 'tr') return;
              i = 0;
              eachElement(row, first, next, function(col) {
                var span;
                span = parseInt(col.getAttribute('span') || 1);
                while (span) {
                  if (check(++i)) set.push(col);
                  span--;
                }
              });
            });
          }
        });
        return intersection(els, set);
      };
    };
    pseudos['column'] = matchColumn(false);
    pseudos['column'].batch = true;
    pseudos['nth-column'] = matchColumn(true);
    pseudos['nth-column'].batch = true;
    pseudos['nth-last-column'] = matchColumn(true, true);
    pseudos['nth-last-column'].batch = true;
    nthMatchPattern = /^(.*?)\s*of\s*(.*)$/;
    nthMatch = function(reversed) {
      return function(els, val, roots) {
        var filtered, len, m, set;
        m = nthPattern.exec(val);
        set = select(m[7], roots);
        len = set.length;
        set.forEach(function(el, i) {
          el._sel_index = (reversed ? len - i : i) + 1;
        });
        filtered = els.filter(function(el) {
          return checkNth(el._sel_index, m);
        });
        set.forEach(function(el, i) {
          el._sel_index = void 0;
        });
        return filtered;
      };
    };
    pseudos['nth-match'] = nthMatch();
    pseudos['nth-match'].batch = true;
    pseudos['nth-last-match'] = nthMatch(true);
    pseudos['nth-last-match'].batch = true;
    nthPositional = function(fn, reversed) {
      var first, next;
      first = reversed ? 'lastChild' : 'firstChild';
      next = reversed ? 'previousSibling' : 'nextSibling';
      return function(els, val) {
        var filtered, m;
        if (val) m = nthPattern.exec(val);
        els.forEach(function(el) {
          var indices, parent;
          if ((parent = el.parentNode) && parent._sel_children === void 0) {
            indices = {
              '*': 0
            };
            eachElement(parent, first, next, function(el) {
              el._sel_index = ++indices['*'];
              el._sel_indexOfType = indices[el.nodeName] = (indices[el.nodeName] || 0) + 1;
            });
            parent._sel_children = indices;
          }
        });
        filtered = els.filter(function(el) {
          return fn(el, m);
        });
        els.forEach(function(el) {
          var parent;
          if ((parent = el.parentNode) && parent._sel_children !== void 0) {
            eachElement(parent, first, next, function(el) {
              el._sel_index = el._sel_indexOfType = void 0;
            });
            parent._sel_children = void 0;
          }
        });
        return filtered;
      };
    };
    positionalPseudos = {
      'first-child': function(el) {
        return el._sel_index === 1;
      },
      'only-child': function(el) {
        return el._sel_index === 1 && el.parentNode._sel_children['*'] === 1;
      },
      'nth-child': function(el, m) {
        return checkNth(el._sel_index, m);
      },
      'first-of-type': function(el) {
        return el._sel_indexOfType === 1;
      },
      'only-of-type': function(el) {
        return el._sel_indexOfType === 1 && el.parentNode._sel_children[el.nodeName] === 1;
      },
      'nth-of-type': function(el, m) {
        return checkNth(el._sel_indexOfType, m);
      }
    };
    for (name in positionalPseudos) {
      fn = positionalPseudos[name];
      pseudos[name] = nthPositional(fn);
      pseudos[name].batch = true;
      if (name.substr(0, 4) !== 'only') {
        name = name.replace('first', 'last').replace('nth', 'nth-last');
        pseudos[name] = nthPositional(fn, true);
        pseudos[name].batch = true;
      }
    }
  })();
  /* eval.coffee
  */
  evaluate = function(e, roots, matchRoots) {
    var els, ids, outerRoots, sibs;
    els = [];
    if (roots.length) {
      switch (e.type) {
        case ' ':
        case '>':
          outerRoots = filterDescendants(roots);
          els = find(e, outerRoots, matchRoots);
          if (e.type === '>') {
            roots.forEach(function(el) {
              el._sel_mark = true;
            });
            els = els.filter(function(el) {
              if (el.parentNode) return el.parentNode._sel_mark;
            });
            roots.forEach(function(el) {
              el._sel_mark = void 0;
            });
          }
          if (e.child) {
            if (e.subject) {
              els = els.filter(function(el) {
                return evaluate(e.child, [el]).length;
              });
            } else {
              els = evaluate(e.child, els);
            }
          }
          break;
        case '+':
        case '~':
        case ',':
        case '/':
          if (e.children.length === 2) {
            sibs = evaluate(e.children[0], roots, matchRoots);
            els = evaluate(e.children[1], roots, matchRoots);
          } else {
            sibs = roots;
            els = evaluate(e.children[0], outerParents(roots), matchRoots);
          }
          if (e.type === ',') {
            els = union(sibs, els);
          } else if (e.type === '/') {
            ids = sibs.map(function(el) {
              return getAttribute(el, e.idref).replace(/^.*?#/, '');
            });
            els = els.filter(function(el) {
              return ~ids.indexOf(el.id);
            });
          } else if (e.type === '+') {
            sibs.forEach(function(el) {
              if ((el = nextElementSibling(el))) el._sel_mark = true;
            });
            els = els.filter(function(el) {
              return el._sel_mark;
            });
            sibs.forEach(function(el) {
              if ((el = nextElementSibling(el))) el._sel_mark = void 0;
            });
          } else if (e.type === '~') {
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
  /* select.coffee
  */
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
  qSA = function(selector, root) {
    var els, id;
    if (root.nodeType === 1) {
      id = root.id;
      if (!id) root.id = '_sel_root';
      selector = "#" + root.id + " " + selector;
    }
    els = root.querySelectorAll(selector);
    if (root.nodeType === 1 && !id) root.removeAttribute('id');
    return els;
  };
  select = html.querySelectorAll ? function(selector, roots, matchRoots) {
    if (!matchRoots && !combinatorPattern.exec(selector)) {
      try {
        return roots.map(function(root) {
          return qSA(selector, root);
        }).reduce(extend, []);
      } catch (e) {

      }
    }
    return evaluate(parse(selector), roots, matchRoots);
  } : function(selector, roots, matchRoots) {
    return evaluate(parse(selector), roots, matchRoots);
  };
  normalizeRoots = function(roots) {
    if (!roots) {
      return [document];
    } else if (typeof roots === 'string') {
      return select(roots, [document]);
    } else if (typeof roots === 'object' && isFinite(roots.length)) {
      if (roots.sort) {
        roots.sort(elCmp);
      } else {
        roots = extend([], roots);
      }
      return roots;
    } else {
      return [roots];
    }
  };
  sel.sel = function(selector, _roots, matchRoots) {
    var roots;
    roots = normalizeRoots(_roots);
    if (!selector) {
      return [];
    } else if (Array.isArray(selector)) {
      return selector;
    } else if (tagPattern.test(selector)) {
      return create(selector, roots[0]);
    } else if (selector === window || selector === 'window') {
      return [window];
    } else if (selector === document || selector === 'document') {
      return [document];
    } else if (selector.nodeType === 1) {
      if (!_roots || roots.some(function(root) {
        return contains(root, selector);
      })) {
        return [selector];
      } else {
        return [];
      }
    } else {
      return select(selector, roots, matchRoots);
    }
  };
  matchesSelector = html.matchesSelector || html.mozMatchesSelector || html.webkitMatchesSelector || html.msMatchesSelector;
  matchesDisconnected = matchesSelector && matchesSelector.call(document.createElement('div'), 'div');
  sel.matching = matching = function(els, selector, roots) {
    if (matchesSelector && (matchesDisconnected || els.every(function(el) {
      return el.document && el.document.nodeType !== 11;
    }))) {
      try {
        return els.filter(function(el) {
          return matchesSelector.call(el, selector);
        });
      } catch (e) {

      }
    }
    e = parse(selector);
    if (!e.child && !e.children && !e.pseudos) {
      return filter(els, e);
    } else {
      return intersection(els, sel.sel(selector, findRoots(els), true));
    }
  };
})(typeof exports !== "undefined" && exports !== null ? exports : (this['sel'] = {}));
