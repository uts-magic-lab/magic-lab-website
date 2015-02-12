
Static site generator for university research lab website.

We use [Gulp](http://gulpjs.com/) to assemble content into static pages that can be served by a CDN. We make use of standard plugins to transpile, concatenate, minify, and render higher-level languages into servable HTML and CSS. Care is taken to choose high-level languages that will age well, such as [polyfill](http://en.wikipedia.org/wiki/Polyfill)s for backwards compatibility of recently established standards.

We store data in a [normalized](http://en.wikipedia.org/wiki/Database_normalization) Google Spreadsheet and use a custom plugin to feed it into the gulp workflow.

Versions of the generated site are stored in source control, which enables diff-based auditing and a push-to-deploy workflow. Push-to-deploy is supported by CDNs such as [GitHub Pages](https://pages.github.com/), and easy to set up on any host with ssh access [by writing a `post-receive` hook](http://nicolasgallagher.com/simple-git-deployment-strategy-for-static-sites/).


### Installation

Install [Node.js](http://nodejs.org/download/) and run
    
    npm install

from the project directory. If you don't want to install `gulp` globally, add the local install to your path:

    export PATH="$PATH:./node_modules/.bin"


### Usage

To generate the website from data and templates, run

    gulp build

then publish the `build` folder.

For development, run

    gulp watch

and navigate to [http://localhost:8000](http://localhost:8000). Changes made to source files should be reflected immediately in your browser.


### Configuration

Gulp encourages a "code over configuration" style, so in many cases it is best to edit the gulpfile directly.

Some situational behavior is controlled by environment variables:

- `GSS_ID`: ID of Google Spreadsheet to fetch data from.

- `MINIFY`: Set to any non-empty value to enable minification of generated HTML and CSS.

- `PORT=8000`: Port to serve site on when using `gulp serve` and `gulp watch`.
