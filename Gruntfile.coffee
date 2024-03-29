# Gruntfile courtesy of trek (https://github.com/trek/)
# ember-todos-with-build-tools-tests-and-other-modern-conveniences
module.exports = (grunt) ->

  # env could be 'dev' or 'prod'
  env = grunt.option("env") or "dev"

  grunt.initConfig
    clean:
      target: ['build', 'dist']

    coffee:
      srcs:
        options:
          bare: true
        expand: true
        cwd: "src/"
        src: [ "**/*.coffee" ]
        dest: "build/src/"
        ext: ".js"

    less:
      development:
        options:
          yuicompress: env isnt "dev"
        files:
          "dist/addepar-bootstrap.css": "less/addepar-bootstrap.less"
      docs:
        options:
          yuicompress: env isnt "dev"
        files:
          "gh_pages/css/docs.css": "docs/assets/css/docs.less"

    ###
      Copy build/docs/assets/css into gh_pages/asset and other assets from docs
    ###
    copy:
      gh_pages:
        files: [
          {src: ['dist/addepar-bootstrap.css'], dest: 'gh_pages/css/addepar-bootstrap.css'},
          {src: ['docs/index.html'], dest: 'gh_pages/index.html'},
          {expand: true, flatten: true, cwd: 'dependencies/', src: ['**/*.js'], dest: 'gh_pages/lib'},
          {expand: true, flatten: true, cwd: 'dependencies/', src: ['**/*.css'], dest: 'gh_pages/css'},
          {expand: true, cwd: 'dependencies/font-awesome/font/', src: ['**'], dest: 'gh_pages/fonts'},
          {expand: true, cwd: 'fonts/', src: ['**'], dest: 'gh_pages/fonts'},
          {expand: true, cwd: 'docs/assets/img/', src: ['**'],  dest: 'gh_pages/img'}
        ]

    ###
      Watch files for changes.

      Changes in dependencies/ember.js or src javascript
      will trigger the neuter task.

      Changes to any templates will trigger the emberTemplates
      task (which writes a new compiled file into dependencies/)
      and then neuter all the files again.
    ###
    watch:
      grunt:
        files: [ "Gruntfile.coffee" ]
        tasks: [ "default" ]
      src:
        files: [ "src/**/*.coffee"]
        tasks: [ "coffee:srcs", "neuter" ]
      src_handlebars:
        files: [ "src/**/*.hbs" ]
        tasks: [ "emberTemplates", "neuter" ]
      docs:
        files: [ "docs/**/*.coffee", "dependencies/**/*.js" ]
        tasks: [ "coffee:docs", "neuter" ]
      docs_handlebars:
        files: [ "docs/**/*.hbs"]
        tasks: [ "emberTemplates", "neuter" ]
      less:
        files: [ "less/**/*.less", "less/**/*.css",
                 "docs/assets/**/*.less", "docs/assets/**/*.css" ]
        tasks: ["less", "copy"]
      copy:
        files: [ "docs/index.html" ]
        tasks: [ "copy" ]

    ###
      Runs all .html files found in the test/ directory through PhantomJS.
      Prints the report in your terminal.
    ###
    qunit:
      all: [ "test/**/*.html" ]

    ###
      Reads the projects .jshintrc file and applies coding
      standards. Doesn't lint the dependencies or test
      support files.
    ###
    jshint:
      all: ['Gruntfile.js', 'src/**/*.js', 'test/**/*.js', '!dependencies/*.*', '!test/support/*.*']
      options:
        jshintrc: ".jshintrc"

    ###
      Find all the <whatever>_test.js files in the test folder.
      These will get loaded via script tags when the task is run.
      This gets run as part of the larger 'test' task registered
      below.
    ###
    build_test_runner_file:
      all: [ "test/**/*_test.js" ]

  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-jshint"
  grunt.loadNpmTasks "grunt-contrib-qunit"
  grunt.loadNpmTasks "grunt-neuter"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-ember-templates"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-clean"

  ###
    A task to build the test runner html file that get place in
    /test so it will be picked up by the qunit task. Will
    place a single <script> tag into the body for every file passed to
    its coniguration above in the grunt.initConfig above.
  ###
  grunt.registerMultiTask "build_test_runner_file", "Creates a test runner file.", ->
    tmpl = grunt.file.read("test/support/runner.html.tmpl")
    renderingContext = data:
      files: @filesSrc.map (fileSrc) -> fileSrc.replace "test/", ""
    grunt.file.write "test/runner.html", grunt.template.process(tmpl, renderingContext)

  grunt.registerTask "build_srcs", [ "coffee:srcs", "emberTemplates", "neuter" ]
  grunt.registerTask "build_docs", [ "coffee:docs", "emberTemplates", "neuter" ]
  if env is "dev"
    grunt.registerTask "default", [ "build_srcs", "build_docs", "less", "copy", "uglify", "watch" ]
  else
    grunt.registerTask "default", [ "less", "build_srcs", "uglify"]
