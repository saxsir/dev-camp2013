'use strict'
mongoose = require 'mongoose'

data_schema = new mongoose.Schema
  json: String
  url: String

page =
  vl: []
  vr: []
  vh: []
  vf: []

error = (message)->
  console.error message
  process.exit()

run = (config)->
  urls = config.urls
  error "urls required" unless urls?
  db = mongoose.connect 'mongodb://localhost/'+config.database
  Page = db.model 'webpages', data_schema

  Page.find {}, (err, docs)->
    for d in docs
      console.log "---\nPage: #{d.url}"
      # さて、ここから分類しますよ...
      data = JSON.parse d.json
      vlRight = getVlRight(data.body, data.nodes)
      console.log "leftbarの右端は #{vlRight} だと判定されました"
      vrLeft = getVrLeft(data.body, data.nodes)
      console.log "rightbarの左端は #{vrLeft} だと判定されました"

      if vlRight < 0 and vrLeft < 0
        console.log '【テンプレートタイプは1か5】'
      else if vlRight > 0 and vrLeft < 0
        console.log '【テンプレートタイプは2か6】'
      else if vlRight < 0 and vrLeft > 0
        console.log '【テンプレートタイプは3か7】'
      else
        console.log '【テンプレートタイプは4か8】'

      vhBottom = getVhBottom(data.body, data.nodes)
      console.log "headerの下端は #{vhBottom} だと判定されました"
      vfTop = getVfTop(data.body, data.nodes)
      console.log "footerの上端は #{vfTop} だと判定されました"

      if vfTop < 0
        console.log 'テンプレートタイプは【1, 2, 3, 4】'
      else
        console.log 'テンプレートタイプは【5, 6, 7, 8】'

    db.disconnect()

getVlRight = (body, nodes)->
  # ページの左端を定義するお
  pageLeft = getLeftEdgeOfPage nodes
  console.log "ページの左端は #{pageLeft} ですよ。"

  # 左端に接しているブロックを取得しますよ
  adjoiningNodes = (->
    range = parseInt body.fontSize
    array = []
    for n in nodes
      array.push(n) if n.left <= pageLeft+range and n.left >= pageLeft-range
    return array
    )()

  console.log "ページの左端に接しているブロックの数は #{adjoiningNodes.length} ですねぇ。"

  # Vlに含まれるブロックを抽出するよ
  limit = body.width/2
  width = 0
  height = 0
  heightAll = 0
  count = 0
  for n in adjoiningNodes
    w = n.width
    h = n.height
    heightAll += h
    if w <= limit
      page.vl.push n
      width += w
      height += h
      count += 1

  # leftbarに含まれるブロックを出力
  console.log "leftbarに含まれると判定されたブロックの数は #{page.vl.length} ですよ。"

  return -1 if height <= heightAll/2
  return pageLeft + width/count

getVrLeft = (body, nodes)->
  # ページの右端を定義するよー
  pageRight = getRightEdgeOfPage nodes
  console.log "ページの右端は #{pageRight} ですよ。"

  # 右端に接しているブロックを取得するよー
  adjoiningNodes = (->
    range = parseInt body.fontSize
    array = []
    for n in nodes
      right = n.width+n.left
      array.push(n) if right <= pageRight+range and right >= pageRight-range
    return array
    )()
  console.log "ページの右端に接しているブロックの数は #{adjoiningNodes.length} ですねぇ。"

  # Vrに含まれるブロックを取得
  limit = body.width/2
  width = 0
  height = 0
  heightAll = 0
  count = 0

  for n in adjoiningNodes
    w = n.width
    h = n.height
    heightAll += h
    if w <= limit
      page.vr.push n
      width += w
      height += h
      count += 1

  console.log "rightbarに含まれると判定されたブロックの数は #{page.vr.length} ですよ。"
  return -1 if height <= heightAll/2
  return pageRight - width/count

getVhBottom = (body, nodes)->
  # ページの上端を定義
  pageTop = getTopEdgeOfPage nodes
  console.log "ページの上端は #{pageTop} ですよ。"

  # 上端に接しているブロックを取得する
  adjoiningNodes = (->
    range = parseInt body.fontSize
    array = []
    for n in nodes
      array.push(n) if n.top <= pageTop+range and n.top >= pageTop-range
    return array
    )()
  console.log "ページの上端に接しているブロックの数は #{adjoiningNodes.length} ですねぇ。"

  # Vhに含まれるブロックを取得
  limit = body.height/2
  width = 0
  height = 0
  widthAll = 0
  count = 0
  for n in adjoiningNodes
    w = n.width
    h = n.height
    widthAll += w
    if h <= limit
      page.vh.push n
      width += w
      height += h
      count += 1

  console.log "headerに含まれると判定されたブロックの数は #{page.vh.length} ですよ。"
  return -1 if width <= widthAll/2
  return pageTop + height/count

getVfTop = (body, nodes)->
  # ページの下端を定義
  pageBottom = getBottomEdgeOfPage nodes
  console.log "ページの下端は #{pageBottom} ですよ。"

  adjoiningNodes = (->
    range = parseInt body.fontSize
    array = []
    for n in nodes
      bottom = n.top+n.height
      array.push(n) if bottom <= pageBottom+range and bottom >= pageBottom-range
    return array
    )()
  console.log "ページの下端に接しているブロックの数は #{adjoiningNodes.length} ですねぇ。"

  limit = body.height/2
  width = 0
  height = 0
  widthAll = 0
  count = 0
  for n in adjoiningNodes
    w = n.width
    h = n.height
    widthAll += w
    if h <= limit
      page.vf.push n
      width += w
      height += h
      count += 1

  console.log "footerに含まれると判定されたブロックの数は #{page.vf.length} ですよ。"
  return -1 if width <= widthAll/2
  return pageBottom - height/count

getLeftEdgeOfPage = (nodes)->
  array = []
  for n in nodes
    array.push n.left
  array.sort (a,b)->
    return a-b

  # 左端から2つ目のleftを
  return array[1]

getRightEdgeOfPage = (nodes)->
  array = []
  for n in nodes
    right = n.left + n.width
    array.push right
  array.sort (a,b)->
    return b-a

  # 右端から2つ目のrightを
  return array[1]

getTopEdgeOfPage = (nodes)->
  array = []
  for n in nodes
    array.push n.top
  array.sort (a,b)->
    return a-b

  return array[1]

getBottomEdgeOfPage = (nodes)->
  array = []
  for n in nodes
    bottom = n.top + n.height
    array.push bottom
  array.sort (a,b)->
    return b-a
  return array[1]

module.exports =
  run: run