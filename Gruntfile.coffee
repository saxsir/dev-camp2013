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

    coffee:
      options:
        bare: yes
      all:
        files:
          'src/js/script.js': 'src/PageRipper.coffee'

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
          'coffee:all'
        ]

    shell:
      mongo:
        command: 'mongod &'

    grunt.registerTask 'default', [
      'shell:mongo'
      'coffeelint:all'
      'coffee:all'
      'watch:all'
    ]