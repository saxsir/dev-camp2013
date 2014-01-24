module.exports = (grunt) ->
  'use strict'
  # パッケージ読み込み
  require('matchdep').filterDev('grunt-*').forEach grunt.loadNpmTasks

  grunt.initConfig
    coffeelint:
      options:
        configFile: '.coffeelint'
      all:
        files:
          src: [
            'Gruntfile.coffee'
            'src/**/*.coffee'
            'bin/*.coffee'
          ]

    watch:
      options:
        interrupt: no
      all:
        files: [
          'Gruntfile.coffee'
          'src/**/*.coffee'
          'bin/*.coffee'
        ]
        tasks: [
          'coffeelint:all'
        ]

    grunt.registerTask 'default', ['coffeelint:all', 'watch:all']