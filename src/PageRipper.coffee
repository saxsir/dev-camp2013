class PageRipper
  constructor: (@d)->
    @
  run: ()->
    data =
      body: {},
      nodes: []

    # 最小ブロック（仮）を取得
    minBlocks = @getMinimumBlocks(@d.body)

    # overflow:hiddenで隠れてるノードを取得
    hiddenBlocks = @getHiddenBlocks(@d.body)

    # 最小ブロック（仮）からhiddenブロック（とその子ノード）を全て削除して親要素を追加
    storage = {}
    for block in hiddenBlocks
      @removeHiddenBlocks minBlocks, block
      unless storage[block.parentNode]
        storage[block.parentNode] = true
        minBlocks.push block.parentNode

    # 最小ブロックのレイアウト情報を取得
    for block in minBlocks
      data.nodes.push @getData(block)

    # bodyのレイアウト情報を取得
    data.body = @getData(@d.body)

    # html書き換え
    error 'html rewrire error' unless @rewriteHtml data

    return data

  ###
    @return {Object} 受け取ったノードのレイアウト情報
  ###
  getData: (node)->
    style = getComputedStyle node
    bounds = node.getBoundingClientRect()
    color = style.color.split ','

    return {
      tagName: node.tagName.toLowerCase()
      width: parseInt bounds.width
      height: parseInt bounds.height
      top: parseInt bounds.top
      left: parseInt bounds.left
      fontSize: style.fontSize
      fontWeight: style.fontWeight
      innerHTML: node.innerHTML.replace /<[^>]*?>/g, ''
      red: color[0].replace /\D/g, ''
      green: color[1].replace /\D/g, ''
      blue: color[2].replace /\D/g, ''
    }

  # 分割後の状態にhtmlを書き換えます
  rewriteHtml: (data)->
    d = @d
    head = d.getElementsByTagName('head')[0]
    body = d.getElementsByTagName('body')[0]
    return false unless @removeChildren head
    return false unless @removeChildren body

    for node in data.nodes
      e = d.createElement 'div'
      style = ''
      style += 'position: absolute;'
      style += "top: #{node.top}px;"
      style += "left: #{node.left}px;"
      style += "width: #{node.width}px;"
      style += "height: #{node.height}px;"
      style += "color: rgb(#{node.red},#{node.green},#{node.blue});"
      style += "font-size: #{node.fontSize}px;"
      style += "font-weight: #{node.fontWeight};"
      style += 'border: 1px solid black'
      e.setAttribute 'style', style
      body.appendChild e

    style = ''
    style += "width: #{data.body.width}px;"
    style += "height: #{data.body.height}px;"
    style += "color: rgb(#{data.body.red}, #{data.body.green}, #{data.body.blue});"
    style += "font-size: #{data.body.fontSize}px;"
    style += "font-weight: #{data.body.fontWeight};"
    body.setAttribute 'style', style
    return true

  removeChildren: (node)->
    elems = node.children
    return false if elems.length is 0
    node.removeChild elems[i] for i in [elems.length-1..0]
    return true

  ###
    @return [Array] 最小ブロックの配列
  ###
  getMinimumBlocks: (node)->
    queue = []
    self = @
    getMinimumBlocks_r = (node)->
      return queue.push(node) if self.isMinimumBlocks(node)
      for child in node.children
        getMinimumBlocks_r(child)

    getMinimumBlocks_r node
    return queue

  isMinimumBlocks: (node)->
    return false unless @isEnableNode node
    if @isBlockElement node
      return true if node.children.length is 0
      for child in node.children
        return false if @isBlockElement child
      return true
    else
      return true if @hasMinimumBlockSiblings node
      return false

  isEnableNode: (node)->
    return false if node.tagName.toLowerCase() is 'script'
    style = getComputedStyle node
    return false if style.display is 'none'
    return false if style.visibility is 'hidden'
    return false if style.opacity is '0'
    bounds = node.getBoundingClientRect()
    return false if bounds.width <= 1 and bounds.height <= 1
    return false if bounds.right <= 0 and bounds.bottom <= 0
    return true

  isBlockElement: (node)->
    return false unless @isEnableNode node
    style = getComputedStyle node
    return true if style.display is 'block'
    blockElements = ['p', 'blockquote', 'pre', 'div', 'noscript', 'hr', 'address', 'fieldset', 'legend', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ul', 'ol', 'li', 'dl', 'dt', 'dd', 'table', 'caption', 'thead', 'tbody', 'colgroup', 'col', 'tr', 'th', 'td', 'embed', 'section', 'article', 'nav', 'aside', 'header', 'footer', 'address']
    return true if blockElements.indexOf(node.tagName.toLowerCase()) isnt -1
    return false

  hasMinimumBlockSiblings: (node)->
    for sibling in node.parentNode.children
      unless node is sibling
        if @isBlockElement sibling
          return true if sibling.children.length is 0
          minBlockFlg = true
          for child in sibling.children
            minBlockFlg = false if @isBlockElement child
            return true if minBlockFlg is true
    return false

  ###
    @note overflow:hidden属性を持つノードの直接の子ノードしか入らない
    @return [Array] overflow:hiddenで隠れてるノードの配列
  ###
  getHiddenBlocks: (node)->
    queue = []
    self = @
    getHiddenBlocks_r = (node)->
      return null if self.isMinimumBlocks node
      style = getComputedStyle node
      if style.overflow is 'hidden'
        bounds = node.getBoundingClientRect()
        top = bounds.top
        left = bounds.left
        right = bounds.right
        bottom = bounds.bottom

        for child in node.children
          childBounds = child.getBoundingClientRect()
          if childBounds.right > right or childBounds.bottom > bottom or childBounds.left < left or childBounds.top < top
            queue.push child

      for child in node.children
        getHiddenBlocks_r child

    getHiddenBlocks_r node
    return queue

  removeHiddenBlocks: (minBlocks, node)->
    # ノードを最小ブロックの配列から削除
    for i in [minBlocks.length-1..0]
      minBlocks.splice(i, 1) if minBlocks[i] is node
    # 子ノードがなければ処理終了
    return null if node.children.length is 0

    for child in node.children
      @removeHiddenBlocks minBlocks, child

