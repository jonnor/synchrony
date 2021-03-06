make =   "make -f ./node_modules/microflo/Makefile"
common_options = [
  "BUILD_DIR=#{process.cwd()}/build"
  "MICROFLO=./node_modules/.bin/microflo"
  "GRAPH=graphs/microsynchro.fbp"
  "MICROFLO_SOURCE_DIR=`pwd`/node_modules/microflo/microflo"
]

microflo = (target) ->
  build = [ make, target ]
  build = build.concat common_options
  return build.join ' '

flash = (device) ->
  build = [ make, "upload", "SERIALPORT=#{device}" ]
  build = build.concat common_options
  return build.join ' '

module.exports = ->
  # Project configuration
  pkg = @file.readJSON 'package.json'
  repo = pkg.repository.url.replace 'git://', 'https://'+process.env.GH_TOKEN+'@'

  @initConfig
    pkg: @file.readJSON 'package.json'

    # MicroFlo
    exec:
      microflo_emscripten: microflo "build-emscripten"
      microflo_arduino: microflo "build-arduino"
      microflo_flash: flash '/dev/ttyACM0'

    # Updating the package manifest files
    noflo_manifest:
      update:
        files:
          'component.json': ['graphs/*', 'components/*']
          'package.json': ['graphs/*', 'components/*']

    # CoffeeScript compilation of tests
    coffee:
      spec:
        options:
          bare: true
        expand: true
        cwd: 'spec'
        src: ['**.coffee']
        dest: 'spec'
        ext: '.js'

    # Browser build of NoFlo
    noflo_browser:
      build:
        options:
          debug: true
        files:
          "browser/<%=pkg.name%>.js": ['component.json']

    # JavaScript minification for the browser
    uglify:
      options:
        report: 'min'
      noflo:
        files:
          "./browser/<%=pkg.name%>.min.js": ["./browser/<%=pkg.name%>.js"]

    # Automated recompilation and testing when developing
    watch:
      files: ['spec/*.coffee', 'components/*.coffee']
      tasks: ['test']

    # BDD tests on Node.js
    cafemocha:
      nodejs:
        src: ['spec/*.coffee']
        options:
          reporter: 'spec'

    # Generate runner.html
    noflo_browser_mocha:
      all:
        options:
          scripts: ["../browser/<%=pkg.name%>.js"]
        files:
          'spec/runner.html': ['spec/*.js']

    # BDD tests on browser
    mocha_phantomjs:
      options:
        output: 'spec/result.xml'
        reporter: 'spec'
      all: ['spec/runner.html']

    # Coding standards
    coffeelint:
      components: ['Gruntfile.coffee', 'spec/*.coffee', 'components/*.coffee']
      options:
        'max_line_length':
          'level': 'ignore'

    'gh-pages':
      options:
        base: 'browser'
        clone: 'gh-pages'
        message: 'Updating'
        repo: repo
        user:
          name: 'NoFlo bot'
          email: 'bot@noflo.org'
        silent: true
      src: '**/*'

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-noflo-manifest'
  @loadNpmTasks 'grunt-noflo-browser'
  @loadNpmTasks 'grunt-contrib-uglify'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-cafe-mocha'
  @loadNpmTasks 'grunt-mocha-phantomjs'
  @loadNpmTasks 'grunt-coffeelint'
  @loadNpmTasks 'grunt-exec'

  # Grunt plugins used for deploying
  @loadNpmTasks 'grunt-gh-pages'

  # Our local tasks
  @registerTask 'build:microflo', '', (target = 'all') =>
    fs = require 'fs'
    if not fs.existsSync 'thirdparty'
        # TEMP HACK
        fs.symlinkSync 'node_modules/microflo/thirdparty', 'thirdparty'
    if target in ['all', 'emscripten']
      @task.run 'exec:microflo_emscripten'
    if target in ['all', 'arduino']
      @task.run 'exec:microflo_arduino'

  @registerTask 'flash', '', () =>
    @task.run 'exec:microflo_flash'

  @registerTask 'build', 'Build NoFlo for the chosen target platform', (target = 'all') =>
    if target is 'all' or target is 'browser' or target is 'nodejs'
      @task.run 'coffee'
      @task.run 'noflo_manifest'
    if target is 'all' or target is 'browser'
      @task.run 'noflo_browser'
      @task.run 'uglify'

  @registerTask 'test', 'Build NoFlo and run automated tests', (target = 'all') =>
    @task.run "build:#{target}"
    if target is 'all' or target is 'nodejs'
      @task.run 'cafemocha'
    if target is 'all' or target is 'browser'
      @task.run 'noflo_browser'
      @task.run 'noflo_browser_mocha'
      @task.run 'mocha_phantomjs'

  @registerTask 'default', ['test']
