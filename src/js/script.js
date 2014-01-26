var PageRipper;

PageRipper = (function() {
  function PageRipper(d) {
    this.d = d;
    this;
  }

  PageRipper.prototype.run = function() {
    var block, data, hiddenBlocks, minBlocks, storage, _i, _j, _len, _len1;
    data = {
      body: {},
      nodes: []
    };
    minBlocks = this.getMinimumBlocks(this.d.body);
    hiddenBlocks = this.getHiddenBlocks(this.d.body);
    storage = {};
    for (_i = 0, _len = hiddenBlocks.length; _i < _len; _i++) {
      block = hiddenBlocks[_i];
      this.removeHiddenBlocks(minBlocks, block);
      if (!storage[block.parentNode]) {
        storage[block.parentNode] = true;
        minBlocks.push(block.parentNode);
      }
    }
    for (_j = 0, _len1 = minBlocks.length; _j < _len1; _j++) {
      block = minBlocks[_j];
      data.nodes.push(this.getData(block));
    }
    data.body = this.getData(this.d.body);
    if (!this.rewriteHtml(data)) {
      error('html rewrire error');
    }
    return data;
  };

  /*
    @return {Object} 受け取ったノードのレイアウト情報
  */


  PageRipper.prototype.getData = function(node) {
    var bounds, color, style;
    style = getComputedStyle(node);
    bounds = node.getBoundingClientRect();
    color = style.color.split(',');
    return {
      tagName: node.tagName.toLowerCase(),
      width: parseInt(bounds.width),
      height: parseInt(bounds.height),
      top: parseInt(bounds.top),
      left: parseInt(bounds.left),
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      innerHTML: node.innerHTML.replace(/<[^>]*?>/g, ''),
      red: color[0].replace(/\D/g, ''),
      green: color[1].replace(/\D/g, ''),
      blue: color[2].replace(/\D/g, '')
    };
  };

  PageRipper.prototype.rewriteHtml = function(data) {
    var body, d, e, head, node, style, _i, _len, _ref;
    d = this.d;
    head = d.getElementsByTagName('head')[0];
    body = d.getElementsByTagName('body')[0];
    if (!this.removeChildren(head)) {
      return false;
    }
    if (!this.removeChildren(body)) {
      return false;
    }
    _ref = data.nodes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      node = _ref[_i];
      e = d.createElement('div');
      style = '';
      style += 'position: absolute;';
      style += "top: " + node.top + "px;";
      style += "left: " + node.left + "px;";
      style += "width: " + node.width + "px;";
      style += "height: " + node.height + "px;";
      style += "color: rgb(" + node.red + "," + node.green + "," + node.blue + ");";
      style += "font-size: " + node.fontSize + "px;";
      style += "font-weight: " + node.fontWeight + ";";
      style += 'border: 1px solid black';
      e.setAttribute('style', style);
      body.appendChild(e);
    }
    style = '';
    style += "width: " + data.body.width + "px;";
    style += "height: " + data.body.height + "px;";
    style += "color: rgb(" + data.body.red + ", " + data.body.green + ", " + data.body.blue + ");";
    style += "font-size: " + data.body.fontSize + "px;";
    style += "font-weight: " + data.body.fontWeight + ";";
    body.setAttribute('style', style);
    return true;
  };

  PageRipper.prototype.removeChildren = function(node) {
    var elems, i, _i, _ref;
    elems = node.children;
    if (elems.length === 0) {
      return false;
    }
    for (i = _i = _ref = elems.length - 1; _ref <= 0 ? _i <= 0 : _i >= 0; i = _ref <= 0 ? ++_i : --_i) {
      node.removeChild(elems[i]);
    }
    return true;
  };

  /*
    @return [Array] 最小ブロックの配列
  */


  PageRipper.prototype.getMinimumBlocks = function(node) {
    var getMinimumBlocks_r, queue, self;
    queue = [];
    self = this;
    getMinimumBlocks_r = function(node) {
      var child, _i, _len, _ref, _results;
      if (self.isMinimumBlocks(node)) {
        return queue.push(node);
      }
      _ref = node.children;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(getMinimumBlocks_r(child));
      }
      return _results;
    };
    getMinimumBlocks_r(node);
    return queue;
  };

  PageRipper.prototype.isMinimumBlocks = function(node) {
    var child, _i, _len, _ref;
    if (!this.isEnableNode(node)) {
      return false;
    }
    if (this.isBlockElement(node)) {
      if (node.children.length === 0) {
        return true;
      }
      _ref = node.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        if (this.isBlockElement(child)) {
          return false;
        }
      }
      return true;
    } else {
      if (this.hasMinimumBlockSiblings(node)) {
        return true;
      }
      return false;
    }
  };

  PageRipper.prototype.isEnableNode = function(node) {
    var bounds, style;
    if (node.tagName.toLowerCase() === 'script') {
      return false;
    }
    style = getComputedStyle(node);
    if (style.display === 'none') {
      return false;
    }
    if (style.visibility === 'hidden') {
      return false;
    }
    if (style.opacity === '0') {
      return false;
    }
    bounds = node.getBoundingClientRect();
    if (bounds.width <= 1 || bounds.height <= 1) {
      return false;
    }
    if (bounds.right <= 0 || bounds.bottom <= 0) {
      return false;
    }
    return true;
  };

  PageRipper.prototype.isBlockElement = function(node) {
    var blockElements, style;
    if (!this.isEnableNode(node)) {
      return false;
    }
    style = getComputedStyle(node);
    if (style.display === 'block') {
      return true;
    }
    blockElements = ['p', 'blockquote', 'pre', 'div', 'noscript', 'hr', 'address', 'fieldset', 'legend', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'dl', 'dt', 'dd', 'table', 'caption', 'thead', 'tbody', 'colgroup', 'col', 'tr', 'th', 'td', 'embed', 'section', 'article', 'nav', 'aside', 'header', 'footer', 'address'];
    if (blockElements.indexOf(node.tagName.toLowerCase()) !== -1) {
      return true;
    }
    return false;
  };

  PageRipper.prototype.hasMinimumBlockSiblings = function(node) {
    var child, minBlockFlg, sibling, _i, _j, _len, _len1, _ref, _ref1;
    _ref = node.parentNode.children;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      sibling = _ref[_i];
      if (node !== sibling) {
        if (this.isBlockElement(sibling)) {
          if (sibling.children.length === 0) {
            return true;
          }
          minBlockFlg = true;
          _ref1 = sibling.children;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            child = _ref1[_j];
            if (this.isBlockElement(child)) {
              minBlockFlg = false;
            }
            if (minBlockFlg === true) {
              return true;
            }
          }
        }
      }
    }
    return false;
  };

  /*
    @note overflow:hidden属性を持つノードの直接の子ノードしか入らない
    @return [Array] overflow:hiddenで隠れてるノードの配列
  */


  PageRipper.prototype.getHiddenBlocks = function(node) {
    var getHiddenBlocks_r, queue, self;
    queue = [];
    self = this;
    getHiddenBlocks_r = function(node) {
      var bottom, bounds, child, childBounds, left, right, style, top, _i, _j, _len, _len1, _ref, _ref1, _results;
      if (self.isMinimumBlocks(node)) {
        return null;
      }
      style = getComputedStyle(node);
      if (style.overflow === 'hidden') {
        bounds = node.getBoundingClientRect();
        top = bounds.top;
        left = bounds.left;
        right = bounds.right;
        bottom = bounds.bottom;
        _ref = node.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          childBounds = child.getBoundingClientRect();
          if (childBounds.right > right || childBounds.bottom > bottom || childBounds.left < left || childBounds.top < top) {
            queue.push(child);
          }
        }
      }
      _ref1 = node.children;
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        child = _ref1[_j];
        _results.push(getHiddenBlocks_r(child));
      }
      return _results;
    };
    getHiddenBlocks_r(node);
    return queue;
  };

  PageRipper.prototype.removeHiddenBlocks = function(minBlocks, node) {
    var child, i, _i, _j, _len, _ref, _ref1, _results;
    for (i = _i = _ref = minBlocks.length - 1; _ref <= 0 ? _i <= 0 : _i >= 0; i = _ref <= 0 ? ++_i : --_i) {
      if (minBlocks[i] === node) {
        minBlocks.splice(i, 1);
      }
    }
    if (node.children.length === 0) {
      return null;
    }
    _ref1 = node.children;
    _results = [];
    for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
      child = _ref1[_j];
      _results.push(this.removeHiddenBlocks(minBlocks, child));
    }
    return _results;
  };

  return PageRipper;

})();
