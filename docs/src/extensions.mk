---
title: Extensions
---

:insert toc


## Installing Plugins

The site extensions directory `ext` is intended for plugins that enhance Ivy's functionality. Python modules or packages placed in this directory will be loaded automatically and can take advantage of Ivy's extension hooks to inject their own code into the build process.

Alternatively, extension modules installed on Python's standard import path can be activated by adding their names to an `extensions` list in the site's configuration file:

::: python

    extensions = [
        'extension_one',
        'extension_two',
    ]

This method can be used to enable extensions installed from the package index using `pip`.



## Event & Filter Hooks

Ivy exports a flexible framework of event and filter hooks. Plugins can extend Ivy by registering callback functions on these hooks.

Most of Ivy's default functionality --- e.g. support for Jinja templates or Markdown files --- is implemented by a set of bundled plugins which make use of this hook system. If you want to extend Ivy yourself you'll probably want to start by taking at look at how they work.

You can find these bundled plugins in the `ivy/ext/` directory which you can view on Github [here][extdir].

[extdir]: https://github.com/dmulholland/ivy/tree/master/ivy/ext




### Events

*Event callbacks* accept zero or more arguments depending on the specific hook. They may modify their arguments in place but have no return value.

Here's a simple event callback that prints a count of the number of pages that have been written to disk:

::: python

    import ivy

    @ivy.hooks.register('exit')
    def print_page_count():
        print(ivy.site.written())

This callback is registered on the `exit` event hook which fires just before the application exits. (The `exit` hook can be found in the `ivy/__init__.py` file.)



### Filters

*Filter callbacks* accept at least one argument --- the value to be filtered. They may accept additional arguments depending on the specific hook. Filter callbacks modify and return the value of their first argument.

Here's a simple filter callback that changes every instance of the word *foo* in node content to *bar*:

::: python

    import ivy

    @ivy.hooks.register('node_text')
    def foo_to_bar(text, node):
        return text.replace('foo', 'bar')

This callback is registered on the `node_text` filter hook which fires just before a node's text is rendered into HTML. (The `node_text` hook can be found in the `ivy/nodes.py` file).

Note that this hook supplies us with the `Node` instance itself as an additional argument which we here ignore.



## Rendering & Parsing Engines

Ivy relies for most of its functionality on a suite of pluggable rendering and parsing engines, e.g. the [Jinja][] template-engine for handling `.jinja` template files. Plugins can register support for additional rendering and parsing engines using a system of `@register` decorators.

[jinja]: http://jinja.pocoo.org



### Templates

Ivy has builtin support for [Jinja][] and [Ibis][] templates. Plugins can register support for additional formats using the `@templates.register()` decorator. Template-engine callbacks are registered per file-extension, e.g.

[jinja]: http://jinja.pocoo.org
[ibis]: https://github.com/dmulholland/ibis

::: python

    import ivy

    @ivy.templates.register('jinja')
    def jinja_callback(page, filename):
        ...
        return html

A template-engine callback should accept a `Page` object and a template filename and return a string of HTML.



### Node Content

Ivy has builtin support for node files written in [Markdown][] and [Monk][]. Plugins can register support for additional formats using the `@renderers.register()` decorator. Rendering-engine callbacks are registered per file-extension, e.g.

[markdown]: https://en.wikipedia.org/wiki/Markdown
[monk]: http://mulholland.xyz/docs/monk/

::: python

    import ivy

    @ivy.renderers.register('md')
    def markdown_callback(text):
        ...
        return html

A rendering-engine callback should accept a single string argument containing plain text and return a string of HTML.



### Node Meta

Ivy has builtin support for YAML file headers. Plugins can add support for additional formats by preprocessing file content on the `file_text` filter hook.

::: python

    import ivy

    @ivy.hooks.register('file_text')
    def parse_toml(text, meta):
        ...
        return text

This filter fires each time a node file is loaded; it passes the raw file text along with a metadata dictionary. Callbacks can check the text for an appropriate header marker, process the header if found, and update the dictionary. They should return the text with the header stripped.

The `file_text` hook can be found in the `ivy/loader.py` file.


## Shortcodes

Ivy has builtin support for WordPress-style [shortcodes][scdocs] with space-separated positional and keyword arguments:

    \[% tag arg1 key=arg2 %]

Arguments containing spaces can be enclosed in quotes:

    \[% tag "arg 1" key="arg 2" %]

Shortcodes can be atomic, as above, or can enclose a block of content between opening and closing tags:

    \[% tag %] ... \[% endtag %]

Block-scoped shortcodes can be nested to any depth. Innermost shortcodes are processed first:

    \[% tag %] ... content with \[% more %] shortcodes ... \[% endtag %]

Plugins can register shortcode tags using the `@shortcodes.register()` decorator:

::: python

    import shortcodes

    @shortcodes.register('tag')
    def handler(node, content, pargs, kwargs):
        ...
        return replacement_text

Specifying a closing tag in the decorator gives the new shortcode block scope:

::: python

    @shortcodes.register('tag', 'endtag')
    def handler(node, content, pargs, kwargs):
        ...
        return replacement_text

Handler functions should accept four arguments:

1. The `Node` instance containing the shortcode.
2. A string containing the shortcode's content, if the shortcode has block
   scope.
3. A list of positional arguments.
4. A dictionary of keyword arguments.

Positional and keyword arguments are passed as strings. The handler function itself should return a string which will replace the shortcode in the text.

Note that shortcodes are processed *before* node text is rendered into HTML.

You can find the full documentation for the Shortcodes library [here][scdocs].

[scdocs]: http://mulholland.xyz/docs/shortcodes/
[scgithub]: https://github.com/dmulholland/shortcodes
