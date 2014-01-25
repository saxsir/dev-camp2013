'use strict'
phantom = require 'phantom'
mongoose = require 'mongoose'

data_schema = new mongoose.Schema
  json: String

error = (message)->
  console.error message
  process.exit()

run = (config)->
  urls = config.urls
  error "urls required" unless urls?

  db = mongoose.connect 'mongodb://localhost/'+config.database

  phantom.create '', (ph)->
    capturePageRecursive ph, urls, db, ->
      # 最後のページの処理が終わるのを3秒待ってからexit
      setTimeout ->
        db.disconnect()
        ph.exit()
      ,3000

capturePageRecursive = (ph, urls, db, callback)->
  # 終了条件
  return callback() if urls.length is 0

  url = urls.shift()
  ph.createPage (page)->
    options =
      width: 1366
      height: 768
    page.set 'viewportSize', options, ->
      page.open url, (status)->
        console.log '['+status+']'+url
        if status is 'success'
          # ページのロードを2秒待ってから実行する
          setTimeout ->
            renderPage page, url, 'original'
            parsePage page, db
            renderPage page, url, 'separated'
            capturePageRecursive ph, urls, db, callback
          ,2000
        else
          capturePageRecursive ph, urls, db, callback

parsePage = (page, db)->
  page.injectJs 'src/js/script.js'
  page.evaluate ->
    do ->
      pageRipper = new PageRipper(document)
      return pageRipper.run()
  ,(result)->
    saveData db, result
    page.close()

renderPage = (page, url, name)->
  filePath = 'logs/'
  for path in url.replace(/^http.*\/\//, '').split '/'
    filePath += path+'/' unless path.length is 0
  page.render filePath + name + '.png'

saveData = (db, data)->
  Page = db.model 'webpages', data_schema
  item = new Page()
  item.json = JSON.stringify(data)
  item.save (e)->
    console.log 'save data'

module.exports = {
  run: run
}